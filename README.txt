= ebay_shopping

* FIX (url)

== DESCRIPTION:

Ebay_Shopping Plugin
===================

The ebay_shopping plugin is a RubyonRails library for Ebay's Shopping API (http://developer.ebay.com/products/shopping/). 
Unlike the trading API (http://developer.ebay.com/products/trading/), the shopping API is only for retrieval of information, not
for posting items, or bidding on them. 

If you need that sort of thing, check out Cody Fauser's gem for the trading API (http://code.google.com/p/ebay/). If you don't, 
the Shopping API is simpler, leaner, and quite a bit faster too.

Ebay_Shopping was developed by Chris Taggart for Autopendium :: Stuff about old cars (http://autopendium.com), a classic car 
community site. It's still in development, and news of updates will be posted at http://pushrod.wordpress.com

Installation
============

To install, simply run the usual: script/plugin install http://ebay-shopping.googlecode.com/svn/trunk/ ebay_shopping

Then from the root of your rails app run ruby vendor/plugins/ebay_shopping/install.rb. 

This will copy a basic configuration file into your app's config directory. This is where
you put your ebay settings (Ebay Application id, affiliate info, etc).

Basic usage
===========

Then from your rails app, construct a new request ebay request:

request = EbayShopping::Request.new(:find_items, {:query_keywords => "chevrolet camaro"}) # use "ruby-ized" version of Ebay API calls and params

response = request.response

response.total_items # => 7081

items_for_sale = response.items

items_for_sale.first.title # => "Chevrolet Camaro"

items_for_sale.first.view_item_url_for_natural_search # => "http://cgi.ebay.com/Chevrolet-Camaro_W0QQitemZ290197239377QQcategoryZ6161QQcmdZViewItemQQ"

items_for_sale.first.gallery_url # => "http://thumbs.ebaystatic.com/pict/290197239377.jpg"

items_for_sale.first.converted_current_price.to_s # => "$38000.00"

...etc

For more methods and more details see the test suite, the comments with the class and method definitions, or wait for me to write more stuff.
== FEATURES/PROBLEMS:

* FIX (list of features or problems)

== SYNOPSIS:

  FIX (code sample of usage)

== REQUIREMENTS:

* FIX (list of requirements)

== INSTALL:

* FIX (sudo gem install, anything else)

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.