--- 
:production: 
  :app_id: 
  :affiliate_partner: "1" # the affiliate provider (aka tracking partner). For Commission Junction this is 1. For others see http://developer.ebay.com/DevZone/shopping/docs/Concepts/ShoppingAPI_FormatOverview.html#AffiliateURLParameters  
  :affiliate_id:  # your site's affiliate id, also known as tracking id, or PID
  :affiliate_shopper_id: "my_campaign" # default campaign identifier, also known (confusingly) as affiliate_user_id, or SID. Only applicable if affiliate provider is Commission Junction
  :default_site_id: # set the default ebay country here (for details see http://developer.ebay.com/DevZone/shopping/docs/CallRef/types/SiteCodeType.html). If this is blank, the US site (site_id=0) is  used by ebay. Can be overridden on individual requests
  
# if you want to have different params for different environments specify them here, otherwise the production settings will be used for that environment
# :development: 
  # :app_id: some other id
  # :affiliate_partner: "1"   
  # :affiliate_id: 
  # :default_site_id: 