require File.dirname(__FILE__) + '/test_helper.rb'


# Tests EbayShopping::Request class.
class TestEbayShopping < Test::Unit::TestCase
  
  def setup
    setup_ebay_responses
    YAML.stubs(:load_file).returns({:production => {:app_id => "foo123"}}) # stub getting of config file
  end
  # 
  # custom exception definition tests
  # 
  def test_should_define_custom_exceptions
    assert EbayShopping::EbayError.superclass            == StandardError
    assert EbayShopping::RequestError.superclass         == EbayShopping::EbayError
    assert EbayShopping::InternalTimeoutError.superclass == EbayShopping::EbayError
    assert EbayShopping::TimeoutError.superclass         == EbayShopping::EbayError
    assert EbayShopping::SystemError.superclass          == EbayShopping::EbayError
  end

  # 
  # EbayShoppingTest::Request tests
  # 
  def test_should_get_configs_from_given_yaml_file
    EbayShopping::Request.class_eval("@@config_params = nil") # reset config params
    YAML.expects(:load_file).with(regexp_matches(/ebay.yml/)).returns({:production => {:app_id => "foo123"}})
    EbayShopping::Request.config_params("/some/path/to/ebay.yml")
  end
  
  def test_should_get_configs_from_yaml_config_file_and_cache_result
    EbayShopping::Request.class_eval("@@config_params = nil") # reset config params
    YAML.expects(:load_file).returns({:production => {:app_id => "foo123"}})
    EbayShopping::Request.config_params("/some/path/to/ebay.yml")
    EbayShopping::Request.config_params("/some/path/to/ebay.yml") # getting the config_params again should use the result stored in the class variable
  end
  
  def test_should_use_production_settings_from_config_file_by_default
    EbayShopping::Request.class_eval("@@config_params = nil") # reset config params
    YAML.stubs(:load_file).returns({:production => {:app_id => "foo123", :affiliate_id => "foo789"}, :development => {:app_id => "456bar"}})
    assert_equal({:app_id => "foo123", :affiliate_id => "foo789"}, EbayShopping::Request.config_params("/some/path/to/ebay.yml"))
  end
  
  def test_should_allow_environment_to_be_specified_for_config_file
    EbayShopping::Request.class_eval("@@config_params = nil") # reset config params
    YAML.expects(:load_file).with(regexp_matches(/ebay.yml/)).returns({:production => {:app_id => "foo123"}, :test => {:app_id => "456bar"}})
    assert_equal "456bar", EbayShopping::Request.config_params("/some/path/to/ebay.yml", :test)[:app_id]
  end  
  
  def test_should_have_callname_and_call_params_accessors
    ebay = EbayShopping::Request.new(:find_items, {:first_param => "foo", :second_param => "bar"})
    assert_equal :find_items, ebay.callname
    assert_equal({:first_param => "foo", :second_param => "bar"}, ebay.call_params)
  end
  
  def test_should_have_app_id_affiliate_id_and_affiliate_partner_accessors_set_from_config_params
    stub_config_params(:affiliate_id => "foo456", :affiliate_partner => "bar789", :affiliate_shopper_id => "foobar")
    assert_equal "app123", new_ebay_request.app_id
    assert_equal "foo456", new_ebay_request.affiliate_id
    assert_equal "bar789", new_ebay_request.affiliate_partner
    assert_equal "foobar", new_ebay_request.affiliate_shopper_id
  end
  
  def test_should_use_default_site_id_if_set_in_config_params
    stub_config_params(:site_id => "foo123")
    assert_equal "foo123", new_ebay_request.site_id
  end
  
  def test_should_use_site_id_for_request_in_preference_to_default_site_id_and_remove_from_call_params
    stub_config_params(:site_id => "foo123")
    ebay = new_ebay_request(:site_id => "456bar")
    assert_equal "456bar", ebay.site_id
    assert_nil ebay.call_params[:site_id] # we don't want it being submitted as a regular param
  end
  
  def test_should_return_site_country_name_from_site_id
    assert_equal "UK", new_ebay_request(:site_id => "3").site_name
    assert_equal "Canada (French)", new_ebay_request(:site_id => "210").site_name
    assert_equal "Sweden", new_ebay_request(:site_id => "218").site_name
    assert_equal "US", new_ebay_request(:site_id => nil).site_name # should return US if site_id is nil (as that's what ebay API defaults to)
  end
  
  def test_should_require_callname_for_new_request
    assert_raise(ArgumentError) { EbayShopping::Request.new }
  end
  
  def test_should_call_cache_methods_when_call_is_made
    request = new_ebay_request
    request.expects(:cached_xml_response)
    request.stubs(:_http_get).returns(@find_items_response)
    request.expects(:cache_response).with(@find_items_response)
    
    request.send(:call, "http://some.url")
  end
  
  def test_should_check_error_cache_when_call_is_made
    request = new_ebay_request
    request.stubs(:_http_get).returns(@find_items_response)
    request.expects(:check_error_cache)
    
    request.send(:call, "http://some.url")
  end
  
  def test_should_build_request_url_from_given_params    
    stub_config_params(:site_id => "3") # no affiliate stuff here
    url = new_ebay_request.send(:url_from, :find_items, {:item_sort => "BestMatch", :max_results => 5} ) # url_from is a protected method
    assert_match "http://open.api.ebay.com/shopping?version=#{EbayShopping::EBAY_API_VERSION}&appid=#{new_ebay_request.app_id}&callname=FindItems&siteid=3&ItemSort=BestMatch&MaxResults=5", url
  end
  
  def test_should_include_affiliate_info_when_building_url_if_given
    stub_config_params(:affiliate_id => "foo456", :affiliate_partner => "bar789", :affiliate_shopper_id => "foobar")
    ebay = new_ebay_request
    assert_equal  "http://open.api.ebay.com/shopping?version=#{EbayShopping::EBAY_API_VERSION}&appid=app123&callname=FindItems" + 
                  "&trackingpartnercode=bar789&trackingid=foo456&affiliateuserid=foobar" + 
                  "&QueryKeywords=dog%20collar", 
                   ebay.send(:url_from, :find_items, {:query_keywords => "dog collar"} ) # url_from is a protected method
  end
  
  def test_should_turn_query_array_into_comma_separated_values
    assert_equal "SomeArray=foo,bar,hello%20world", new_ebay_request.send(:_query_params_from, {:some_array => ["foo", "bar", "hello world"]} ) # url_from is a protected method
  end
  
  def test_should_always_return_query_params_in_alpha_order
    assert_equal "ItemSort=BestMatch&MaxResults=5&QueryKeywords=dog%20collar", new_ebay_request.send(:_query_params_from, {:query_keywords => "dog collar", :item_sort => "BestMatch", :max_results => 5} ) # url_from is a protected method
    assert_equal "ItemSort=BestMatch&MaxResults=5&QueryKeywords=dog%20collar", new_ebay_request.send(:_query_params_from, {:item_sort => "BestMatch", :max_results => 5, :query_keywords => "dog collar"} ) # url_from is a protected method
  end
  
  def test_should_ignore_query_params_with_nil_value
    stub_config_params
    ebay = new_ebay_request
    assert_equal "Foo=hello%20world", ebay.send(:_query_params_from, {:foo => "hello world", :bar => nil} ) 
  end
  
  def test_should_call_ebay_shopping_url_when_ebay_response_is_requested
    EbayShopping::Request.any_instance.expects(:url_from).returns("http://ebay.com/some_url")
    EbayShopping::Request.any_instance.expects(:call).with("http://ebay.com/some_url").returns(@find_items_response)
    
    new_ebay_request.response
  end
   
  def test_should_return_appropriate_response_object_for_request_response
    EbayShopping::Request.any_instance.stubs(:call).returns(@find_items_response)
    
    assert_kind_of EbayShopping::FindItemsResponse, EbayShopping::Request.new(:find_items).response    
    assert_kind_of EbayShopping::FindItemsAdvancedResponse, EbayShopping::Request.new(:find_items_advanced).response    
    assert_kind_of EbayShopping::FindPopularItemsResponse, EbayShopping::Request.new(:find_popular_items).response    
    assert_kind_of EbayShopping::GetMultipleItemsResponse, EbayShopping::Request.new(:get_multiple_items).response    
    assert_kind_of EbayShopping::GetSingleItemResponse, EbayShopping::Request.new(:get_single_item).response    
    assert_kind_of EbayShopping::GetCategoryInfoResponse, EbayShopping::Request.new(:get_category_info).response    
    assert_kind_of EbayShopping::FindProductsResponse, EbayShopping::Request.new(:find_products).response    
  end
  
  def test_should_pass_self_to_response_object_so_request_is_accessible_from_response_object
    request = new_ebay_request
    EbayShopping::Request.any_instance.stubs(:call).returns(@find_items_response)
    EbayShopping::FindItemsResponse.expects(:new).with(anything, request)
    
    request.response
  end
  
  # 
  # EbayShoppingTest::Response tests
  # 
  def test_should_instantiate_response_object_from_xml_and_parse_into_hash
    response = EbayShopping::Response.new(@find_items_response)
    assert_kind_of Hash, response.full_response
  end
  
  def test_should_return_request_that_generated_response
    EbayShopping::Request.any_instance.stubs(:call).returns(@find_items_response)
    request = new_ebay_request
    response = request.response

    assert_equal request, response.request
  end
  
  def test_should_extract_total_results_from_xml_response
    response = EbayShopping::Response.new(@find_items_response)
    assert_equal 117, response.total_items
  end
  
  def test_should_return_nil_for_total_items_if_no_total_items_field
    response = EbayShopping::Response.new(@get_single_item_response)
    assert_nil response.total_items
  end
  
  def test_should_extract_page_number_from_xml_response
    response = EbayShopping::Response.new(@find_items_advanced_response)
    assert_equal 1, response.page_number
  end
  
  def test_should_return_nil_for_page_number_if_no_total_items_field
    response = EbayShopping::Response.new(@get_single_item_response)
    assert_nil response.page_number
  end
  
  def test_should_extract_total_pages_from_xml_response
    response = EbayShopping::Response.new(@find_items_advanced_response)
    assert_equal 5, response.total_pages
  end
  
  def test_should_return_nil_for_total_pages_from_xml_response_if_no_total_pages_field
    response = EbayShopping::Response.new(@get_single_item_response)
    assert_nil response.total_pages
  end
  
  def test_should_return_nil_for_errors_if_no_errors
    response = EbayShopping::Response.new(@find_items_response)
    assert_nil response.errors
  end
  
  def test_should_extract_items_from_response_in_basic_response_object
    response = EbayShopping::Response.new(@find_items_response)
    assert_kind_of Array, items = response.items
    assert_kind_of EbayShopping::Item, items.first
    assert_equal "1949 CADILLAC COUPE DeVILLE- WHITE DIECAST 1:43 SCALE", items.first.title
  end
  
  def test_should_still_return_array_of_items_from_response_even_when_only_one_item
    response = EbayShopping::Response.new(@find_items_response)
    response.stubs(:xml_items).returns(response.full_response["Item"].first) # simulate only one item being returned
    assert_kind_of Array, items = response.items
    assert_equal 1, items.size
    assert_kind_of EbayShopping::Item, items.first
    assert_equal "1949 CADILLAC COUPE DeVILLE- WHITE DIECAST 1:43 SCALE", items.first.title
  end
  
  def test_should_extract_items_from_find_items_response
    response = EbayShopping::FindItemsResponse.new(@find_items_response)
    assert_kind_of Array, items = response.items
    assert_kind_of EbayShopping::Item, items.first
    assert_equal "1949 CADILLAC COUPE DeVILLE- WHITE DIECAST 1:43 SCALE", items.first.title
  end
  
  def test_should_extract_items_from_find_items_advanced_response
    response = EbayShopping::FindItemsAdvancedResponse.new(@find_items_advanced_response)
    assert_kind_of Array, items = response.items
    assert_kind_of EbayShopping::Item, items.first
    assert_equal "Original Soundtrack - Harry Potter And The Philosoph...", items.first.title
  end
  
  def test_should_extract_items_from_get_single_item_response
    response = EbayShopping::GetSingleItemResponse.new(@get_single_item_response)
    assert_kind_of Array, items = response.items
    assert_kind_of EbayShopping::Item, items.first
    assert_equal "EMMA WATSON entertainment weekly HARRY POTTER phoenix", items.first.title
  end
  
  def test_should_have_item_accessor_for_single_item_response
    response = EbayShopping::GetSingleItemResponse.new(@get_single_item_response)
    assert_equal response.items.first, response.item
  end
  
  def test_should_extract_items_from_find_popular_items_response
    response = EbayShopping::FindPopularItemsResponse.new(@find_popular_items_response)
    assert_kind_of Array, items = response.items
    assert_kind_of EbayShopping::Item, items.first
    assert_equal "Harry Potter And The Chamber Of Secrets - Original S...", items.first.title
  end
  
  def test_should_extract_items_from_get_multiple_items_response
    response = EbayShopping::GetMultipleItemsResponse.new(@get_multiple_items_response)
    assert_kind_of Array, items = response.items
    assert_kind_of EbayShopping::Item, items.first
    assert_equal "harry potter gwq minimium", items.first.title
  end
  
  def test_should_extract_products_from_find_products_response
    response = EbayShopping::FindProductsResponse.new(@find_products_response)
    assert_kind_of Array, products = response.products
    assert_kind_of EbayShopping::Product, products.first
    assert_equal "Harry Potter and the Order of the Phoenix (2007, DVD)", products.first.title
  end
  
  def test_should_return_no_results_if_no_results
    EbayShopping::Request.any_instance.expects(:call).returns(@no_results_response)
    response = new_ebay_request.response
    assert_equal [], response.items
  end
  
  def test_should_raise_request_error_if_request_error_response
    EbayShopping::Request.any_instance.expects(:call).returns(@request_error_response)
    assert_raise(EbayShopping::RequestError) { new_ebay_request.response }
  end
  
  def test_should_raise_system_error_if_system_error_response
    EbayShopping::Request.any_instance.expects(:call).returns(@system_error_response)
    assert_raise(EbayShopping::SystemError) { new_ebay_request.response }
  end
  
  def test_should_raise_internal_timeout_if_ebay_timeout_error_response
    assert_raise(EbayShopping::InternalTimeoutError) { EbayShopping::Response.new(@timeout_error_response, new_ebay_request) }
  end
  
  def test_should_rescue_internal_timeout_error_once_and_make_call_again_and_set_repeat_call_accessor
    EbayShopping::Request.any_instance.expects(:call).times(2).returns(@timeout_error_response).then.returns(@find_items_response)
    response = new_ebay_request.response
    assert response.request.repeat_call
  end
  
  def test_should_rescue_internal_timeout_error_only_once_and_raise_if_returned_a_second_time
    EbayShopping::Request.any_instance.expects(:call).times(2).returns(@timeout_error_response)
    assert_raise(EbayShopping::SystemError) { new_ebay_request.response }
  end
  
  def test_should_rescue_timeout_error_and_raise_ebay_timeout_instead
    Net::HTTP.any_instance.expects(:get).raises(Timeout::Error, "Timeout::Error")
    assert_raise(EbayShopping::TimeoutError) { new_ebay_request.response }
  end
  
  def test_should_raise_ebay_request_error_if_error_code_returned
    Net::HTTP.any_instance.expects(:get).returns(Net::HTTPBadRequest.new("1.1","400","Bad Request"))
    assert_raise(EbayShopping::RequestError) { new_ebay_request.response }
  end
  
  def test_should_call_ebay_error_raised_hook_when_request_error_raised
    request = new_ebay_request
    request.expects(:call).returns(@request_error_response)
    request.expects(:ebay_error_raised).with(has_entry("LongMessage", "Input data for the given tag is invalid or missing. Please check API documentation."))

    assert_raise(EbayShopping::RequestError) { request.response }
  end
  
  def test_should_call_system_error_called_hook_when_system_error_raised
    request = new_ebay_request
    request.expects(:call).returns(@system_error_response)
    request.expects(:ebay_error_raised)

    assert_raise(EbayShopping::SystemError) { request.response }
  end
  
  # EbayShoppingTest::GenericItem tests
  def test_should_instantiate_generic_item_from_hash_and_convert_params_into_accessors
    item = EbayShopping::GenericItem.new("Title" => "Dummy ebay item")
    assert_equal "Dummy ebay item", item.title
  end
  
  def test_should_make_items_original_hash_available_as_all_params
    item = EbayShopping::GenericItem.new("ItemID" => "foo123", "Title" => "Dummy ebay item")
    assert_equal({"ItemID" => "foo123", "Title" => "Dummy ebay item"}, item.all_params)
  end
  
  def test_should_allow_access_to_original_hash_via_square_brackets
    item = EbayShopping::GenericItem.new("ItemID" => "foo123", "Title" => "Dummy ebay item")
    assert_equal "foo123", item["ItemID"]
    assert_equal "Dummy ebay item", item["Title"]
  end
  
  def test_should_not_instantiate_instance_variable_for_attributes_with_no_accessor
    item = EbayShopping::GenericItem.new("ItemID" => "foo123", "foo" => "bar")
    assert !item.instance_variables.include?("@foo")
  end
  
  # EbayShoppingTest::Item tests
  def test_should_instantiate_ebay_item_from_hash_and_convert_params_into_accessors
    item = EbayShopping::Item.new("ItemID" => "foo123", "Title" => "Dummy ebay item")
    assert_equal "foo123", item.item_id
    assert_equal "Dummy ebay item", item.title
  end
  
  def test_should_return_converted_current_price_as_money_object
    item = EbayShopping::Item.new("ItemID" => "foo123", "ConvertedCurrentPrice"=>{"currencyID"=>"GBP", "content"=>"0.99"})
    assert_kind_of EbayShopping::Money, item.converted_current_price
  end
  
  def test_should_return_nil_for_converted_current_price_if_no_such_attribute
    item = EbayShopping::Item.new("ItemID" => "foo123")
    assert_nil item.converted_current_price
  end
  
  def test_should_return_formatted_time_left
    dummy_time = Time.now + ((3*24 + 4)*60 + 32)*60+1
    item = EbayShopping::Item.new("ItemID" => "foo123", "EndTime"=>dummy_time.xmlschema)
    assert_equal "3 days, 4 hours, 32 minutes", item.time_left
  end
  
  def test_should_return_end_time_as_time_object
    item = EbayShopping::Item.new("ItemID" => "foo123", "EndTime"=>"2008-01-06T22:50:09.000Z")
    assert_kind_of Time, item.end_time
    assert_equal "Sun Jan 06 22:50:09 +0000 2008", item.end_time.to_s
  end
  
  # EbayShoppingTest::Product tests
  def test_should_instantiate_ebay_product_from_hash_and_convert_params_into_accessors
    item = EbayShopping::Product.new("ProductID" => "foo123", "Title" => "Dummy ebay product")
    assert_equal "foo123", item.product_id
    assert_equal "Dummy ebay product", item.title
  end
  
  # EbayShoppingTest::Money tests
  def test_should_instantiate_money_object_from_hash
    money = EbayShopping::Money.new("currencyID"=>"GBP", "content"=>"5.99")
    assert_equal "GBP", money.currency_id
    assert_in_delta(5.99, money.content, 2 ** -20)
  end
  
  def test_should_convert_money_to_s_in_standard_format
    money = EbayShopping::Money.new("currencyID"=>"FOO", "content"=>"5.99123")
    assert_equal "FOO 5.99", money.to_s
  end
  
  def test_should_convert_money_to_s_in_for_common_currencies
    assert_equal "£5.99", EbayShopping::Money.new("currencyID"=>"GBP", "content"=>"5.99123").to_s
    assert_equal "$5.99", EbayShopping::Money.new("currencyID"=>"USD", "content"=>"5.99123").to_s
    assert_equal "AU$5.99", EbayShopping::Money.new("currencyID"=>"AUD", "content"=>"5.99123").to_s
    assert_equal "CA$5.99", EbayShopping::Money.new("currencyID"=>"CAD", "content"=>"5.99123").to_s
    assert_equal "EUR 5.99", EbayShopping::Money.new("currencyID"=>"EUR", "content"=>"5.99123").to_s
  end
  
  private
  def dummy_xml_response(response_name)
    IO.read(File.join(File.dirname(__FILE__) + "/xml_responses/#{response_name.to_s}.xml"))
  end
  
  def new_ebay_request(options={})
    EbayShopping::Request.new(:find_items, options)
  end
  
  def stub_config_params(options={})
    EbayShopping::Request.stubs(:config_params).returns({:app_id => "app123"}.merge(options))
  end
  
  def setup_ebay_responses
    @find_items_response          = dummy_xml_response(:ebay_find_items)
    @find_items_advanced_response = dummy_xml_response(:ebay_find_items_advanced)
    @find_popular_items_response  = dummy_xml_response(:ebay_find_popular_items)
    @get_multiple_items_response  = dummy_xml_response(:ebay_get_multiple_items)
    @get_single_item_response     = dummy_xml_response(:ebay_get_single_item)
    @get_category_info_response   = dummy_xml_response(:ebay_get_category_info)
    @find_products_response       = dummy_xml_response(:ebay_find_products)
    @no_results_response          = dummy_xml_response(:ebay_no_results)
    @request_error_response       = dummy_xml_response(:ebay_request_error)
    @system_error_response        = dummy_xml_response(:ebay_system_error)
    @timeout_error_response       = dummy_xml_response(:ebay_timeout_error)
  end
end

