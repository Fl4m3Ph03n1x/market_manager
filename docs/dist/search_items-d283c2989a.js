searchNodes=[{"doc":"Port for http client.","ref":"AuctionHouse.html","title":"AuctionHouse","type":"behaviour"},{"doc":"See AuctionHouse.HTTPClient.delete_order/1.","ref":"AuctionHouse.html#delete_order/1","title":"AuctionHouse.delete_order/1","type":"function"},{"doc":"","ref":"AuctionHouse.html#c:delete_order/1","title":"AuctionHouse.delete_order/1","type":"callback"},{"doc":"","ref":"AuctionHouse.html#c:delete_order/2","title":"AuctionHouse.delete_order/2","type":"callback"},{"doc":"See AuctionHouse.HTTPClient.get_all_orders/1.","ref":"AuctionHouse.html#get_all_orders/1","title":"AuctionHouse.get_all_orders/1","type":"function"},{"doc":"","ref":"AuctionHouse.html#c:get_all_orders/1","title":"AuctionHouse.get_all_orders/1","type":"callback"},{"doc":"","ref":"AuctionHouse.html#c:get_all_orders/2","title":"AuctionHouse.get_all_orders/2","type":"callback"},{"doc":"See AuctionHouse.HTTPClient.place_order/1.","ref":"AuctionHouse.html#place_order/1","title":"AuctionHouse.place_order/1","type":"function"},{"doc":"","ref":"AuctionHouse.html#c:place_order/1","title":"AuctionHouse.place_order/1","type":"callback"},{"doc":"","ref":"AuctionHouse.html#c:place_order/2","title":"AuctionHouse.place_order/2","type":"callback"},{"doc":"","ref":"AuctionHouse.html#t:delete_order_response/0","title":"AuctionHouse.delete_order_response/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:deps/0","title":"AuctionHouse.deps/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:get_all_orders_response/0","title":"AuctionHouse.get_all_orders_response/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:item_id/0","title":"AuctionHouse.item_id/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:item_name/0","title":"AuctionHouse.item_name/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:order/0","title":"AuctionHouse.order/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:order_id/0","title":"AuctionHouse.order_id/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:order_info/0","title":"AuctionHouse.order_info/0","type":"type"},{"doc":"","ref":"AuctionHouse.html#t:place_order_response/0","title":"AuctionHouse.place_order_response/0","type":"type"},{"doc":"Adapter for the interface AuctionHouse","ref":"AuctionHouse.HTTPClient.html","title":"AuctionHouse.HTTPClient","type":"module"},{"doc":"Holds configurations that do not depend on the environment. 12 factor app standard states that only configurations that depend on the environment should be configurable in config files (config folder).Since these variables are all compile time, no matter the environment they are used for, this module will hold them.","ref":"AuctionHouse.Settings.html","title":"AuctionHouse.Settings","type":"module"},{"doc":"Returns the name of the throttling queue used to make requests to warframe.market.","ref":"AuctionHouse.Settings.html#requests_queue/0","title":"AuctionHouse.Settings.requests_queue/0","type":"function"},{"doc":"synopsis: Manages sell orders in warframe.market. usage: $ ./market_manager {options} example: ./market_manager --action=activate --syndicates=new_loka,red_veil --strategy=equal_to_lowest options: --action=activate|deactivateCan be either &#39;activate&#39; or &#39;deactivate&#39;. Activating a syndicate means placing a sell order on warframe.market for each item the syndicate has that is in the *products.json* file. Deactivating a syndicate deletes all orders in warframe.market from the given syndicate. --syndicates=syndicate1,syndicate2Syndicates to be affected by the action. --strategy=top_five_average|top_three_average|equal_to_lowest|lowest_minus_oneThe strategy used by the price analysr to calculate the price at which your items should be sold.","ref":"Cli.html","title":"Cli","type":"module"},{"doc":"Receives the input from the user, parses it and sends it to the Manager. Returns whatever response the Manager gave or an error message if the input was malformed.Can be invoked with [&quot;-h&quot;] to see the help logs.","ref":"Cli.html#main/2","title":"Cli.main/2","type":"function"},{"doc":"","ref":"Cli.html#t:action/0","title":"Cli.action/0","type":"type"},{"doc":"","ref":"Cli.html#t:args/0","title":"Cli.args/0","type":"type"},{"doc":"","ref":"Cli.html#t:dependecies/0","title":"Cli.dependecies/0","type":"type"},{"doc":"","ref":"Cli.html#t:strategy/0","title":"Cli.strategy/0","type":"type"},{"doc":"","ref":"Cli.html#t:syndicate/0","title":"Cli.syndicate/0","type":"type"},{"doc":"MarketManager is an application that allows you to make batch requests to warframe.market. This is the entrypoint of everything. If you have a module and you need to talk to MarketManager, this is who you call, the public API.","ref":"Cli.Manager.html","title":"Cli.Manager","type":"behaviour"},{"doc":"","ref":"Cli.Manager.html#c:activate/2","title":"Cli.Manager.activate/2","type":"callback"},{"doc":"","ref":"Cli.Manager.html#c:deactivate/1","title":"Cli.Manager.deactivate/1","type":"callback"},{"doc":"","ref":"Cli.Manager.html#c:valid_strategy?/1","title":"Cli.Manager.valid_strategy?/1","type":"callback"},{"doc":"","ref":"Cli.Manager.html#t:activate_response/0","title":"Cli.Manager.activate_response/0","type":"type"},{"doc":"","ref":"Cli.Manager.html#t:deactivate_response/0","title":"Cli.Manager.deactivate_response/0","type":"type"},{"doc":"","ref":"Cli.Manager.html#t:error_reason/0","title":"Cli.Manager.error_reason/0","type":"type"},{"doc":"","ref":"Cli.Manager.html#t:item_id/0","title":"Cli.Manager.item_id/0","type":"type"},{"doc":"","ref":"Cli.Manager.html#t:order_id/0","title":"Cli.Manager.order_id/0","type":"type"},{"doc":"","ref":"Cli.Manager.html#t:strategy/0","title":"Cli.Manager.strategy/0","type":"type"},{"doc":"","ref":"Cli.Manager.html#t:syndicate/0","title":"Cli.Manager.syndicate/0","type":"type"},{"doc":"MarketManager is an application that allows you to make batch requests to warframe.market. This is the entrypoint of everything. If you have a module and you need to talk to MarketManager, this is who you call, the public API.","ref":"Manager.html","title":"Manager","type":"module"},{"doc":"Activates a syndicate in warframe.market. Activating a syndicate means you put on sell all the mods the syndicate has with that are in the products.json file. The price of each mod will be calculated via a PriceAnalyst depending on which strategy you choose.Example:{:ok, :success} = MarketManager.activate(&quot;simaris&quot;, :lowest_minus_one)","ref":"Manager.html#activate/2","title":"Manager.activate/2","type":"function"},{"doc":"Deactivates a syndicate in warframe.market. Deactivating a syndicate means you delete all orders you have placed before that belong to the given syndicate.Example:{:ok, :success} = MarketManager.deactivate(&quot;simaris&quot;)","ref":"Manager.html#deactivate/1","title":"Manager.deactivate/1","type":"function"},{"doc":"Returns true if the given strategy is valid, false otherwise.Example:MarketManager.valid_strategy?(&quot;bananas&quot;) # false MarketManager.valid_strategy?(&quot;equal_to_lowest&quot;) # true","ref":"Manager.html#valid_strategy?/1","title":"Manager.valid_strategy?/1","type":"function"},{"doc":"","ref":"Manager.html#t:activate_response/0","title":"Manager.activate_response/0","type":"type"},{"doc":"","ref":"Manager.html#t:deactivate_response/0","title":"Manager.deactivate_response/0","type":"type"},{"doc":"","ref":"Manager.html#t:error_reason/0","title":"Manager.error_reason/0","type":"type"},{"doc":"","ref":"Manager.html#t:item_id/0","title":"Manager.item_id/0","type":"type"},{"doc":"","ref":"Manager.html#t:order_id/0","title":"Manager.order_id/0","type":"type"},{"doc":"","ref":"Manager.html#t:strategy/0","title":"Manager.strategy/0","type":"type"},{"doc":"","ref":"Manager.html#t:syndicate/0","title":"Manager.syndicate/0","type":"type"},{"doc":"Port for http client.","ref":"Manager.AuctionHouse.html","title":"Manager.AuctionHouse","type":"behaviour"},{"doc":"","ref":"Manager.AuctionHouse.html#c:delete_order/1","title":"Manager.AuctionHouse.delete_order/1","type":"callback"},{"doc":"","ref":"Manager.AuctionHouse.html#c:get_all_orders/1","title":"Manager.AuctionHouse.get_all_orders/1","type":"callback"},{"doc":"","ref":"Manager.AuctionHouse.html#c:place_order/1","title":"Manager.AuctionHouse.place_order/1","type":"callback"},{"doc":"","ref":"Manager.AuctionHouse.html#t:delete_order_response/0","title":"Manager.AuctionHouse.delete_order_response/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:deps/0","title":"Manager.AuctionHouse.deps/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:get_all_orders_response/0","title":"Manager.AuctionHouse.get_all_orders_response/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:item_id/0","title":"Manager.AuctionHouse.item_id/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:item_name/0","title":"Manager.AuctionHouse.item_name/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:order/0","title":"Manager.AuctionHouse.order/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:order_id/0","title":"Manager.AuctionHouse.order_id/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:order_info/0","title":"Manager.AuctionHouse.order_info/0","type":"type"},{"doc":"","ref":"Manager.AuctionHouse.html#t:place_order_response/0","title":"Manager.AuctionHouse.place_order_response/0","type":"type"},{"doc":"Core of the manager, where all the logic and communication with outer layers is. Currently, it works more like a bridge between the different ports of the application and manages data between them.","ref":"Manager.Interpreter.html","title":"Manager.Interpreter","type":"module"},{"doc":"","ref":"Manager.Interpreter.html#activate/3","title":"Manager.Interpreter.activate/3","type":"function"},{"doc":"","ref":"Manager.Interpreter.html#deactivate/2","title":"Manager.Interpreter.deactivate/2","type":"function"},{"doc":"","ref":"Manager.Interpreter.html#t:order_request/0","title":"Manager.Interpreter.order_request/0","type":"type"},{"doc":"","ref":"Manager.Interpreter.html#t:order_request_without_rank/0","title":"Manager.Interpreter.order_request_without_rank/0","type":"type"},{"doc":"Contains the formulas and calculations for all the strategies. Strategies calculate the optimum price for you to sell an item. There are several stretagies, some focus more on selling fast, while others on getting more profit.","ref":"Manager.PriceAnalyst.html","title":"Manager.PriceAnalyst","type":"module"},{"doc":"","ref":"Manager.PriceAnalyst.html#calculate_price/2","title":"Manager.PriceAnalyst.calculate_price/2","type":"function"},{"doc":"","ref":"Manager.PriceAnalyst.html#valid_strategy?/1","title":"Manager.PriceAnalyst.valid_strategy?/1","type":"function"},{"doc":"Port for the persistency layer.","ref":"Manager.Store.html","title":"Manager.Store","type":"behaviour"},{"doc":"","ref":"Manager.Store.html#c:delete_order/2","title":"Manager.Store.delete_order/2","type":"callback"},{"doc":"","ref":"Manager.Store.html#c:list_orders/1","title":"Manager.Store.list_orders/1","type":"callback"},{"doc":"","ref":"Manager.Store.html#c:list_products/1","title":"Manager.Store.list_products/1","type":"callback"},{"doc":"","ref":"Manager.Store.html#c:save_order/2","title":"Manager.Store.save_order/2","type":"callback"},{"doc":"","ref":"Manager.Store.html#t:all_orders_store/0","title":"Manager.Store.all_orders_store/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:delete_order_response/0","title":"Manager.Store.delete_order_response/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:deps/0","title":"Manager.Store.deps/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:list_orders_response/0","title":"Manager.Store.list_orders_response/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:list_products_response/0","title":"Manager.Store.list_products_response/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:order_id/0","title":"Manager.Store.order_id/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:product/0","title":"Manager.Store.product/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:save_order_response/0","title":"Manager.Store.save_order_response/0","type":"type"},{"doc":"","ref":"Manager.Store.html#t:syndicate/0","title":"Manager.Store.syndicate/0","type":"type"},{"doc":"Port for the persistency layer.","ref":"Store.html","title":"Store","type":"behaviour"},{"doc":"See Store.FileSystem.delete_order/2.","ref":"Store.html#delete_order/2","title":"Store.delete_order/2","type":"function"},{"doc":"","ref":"Store.html#c:delete_order/2","title":"Store.delete_order/2","type":"callback"},{"doc":"","ref":"Store.html#c:delete_order/3","title":"Store.delete_order/3","type":"callback"},{"doc":"See Store.FileSystem.list_orders/1.","ref":"Store.html#list_orders/1","title":"Store.list_orders/1","type":"function"},{"doc":"","ref":"Store.html#c:list_orders/1","title":"Store.list_orders/1","type":"callback"},{"doc":"","ref":"Store.html#c:list_orders/2","title":"Store.list_orders/2","type":"callback"},{"doc":"See Store.FileSystem.list_products/1.","ref":"Store.html#list_products/1","title":"Store.list_products/1","type":"function"},{"doc":"","ref":"Store.html#c:list_products/1","title":"Store.list_products/1","type":"callback"},{"doc":"","ref":"Store.html#c:list_products/2","title":"Store.list_products/2","type":"callback"},{"doc":"See Store.FileSystem.save_order/2.","ref":"Store.html#save_order/2","title":"Store.save_order/2","type":"function"},{"doc":"","ref":"Store.html#c:save_order/2","title":"Store.save_order/2","type":"callback"},{"doc":"","ref":"Store.html#c:save_order/3","title":"Store.save_order/3","type":"callback"},{"doc":"","ref":"Store.html#t:all_orders_store/0","title":"Store.all_orders_store/0","type":"type"},{"doc":"","ref":"Store.html#t:delete_order_response/0","title":"Store.delete_order_response/0","type":"type"},{"doc":"","ref":"Store.html#t:deps/0","title":"Store.deps/0","type":"type"},{"doc":"","ref":"Store.html#t:list_orders_response/0","title":"Store.list_orders_response/0","type":"type"},{"doc":"","ref":"Store.html#t:list_products_response/0","title":"Store.list_products_response/0","type":"type"},{"doc":"","ref":"Store.html#t:order_id/0","title":"Store.order_id/0","type":"type"},{"doc":"","ref":"Store.html#t:product/0","title":"Store.product/0","type":"type"},{"doc":"","ref":"Store.html#t:save_order_response/0","title":"Store.save_order_response/0","type":"type"},{"doc":"","ref":"Store.html#t:syndicate/0","title":"Store.syndicate/0","type":"type"},{"doc":"Adapter for the Store port, implements it using the file system.","ref":"Store.FileSystem.html","title":"Store.FileSystem","type":"module"},{"doc":"&lt;a href=&quot;https://fl4m3ph03n1x.github.io/market_manager/&quot;&gt; &lt;img src=&quot;images/logo.png&quot; alt=&quot;Logo&quot; width=&quot;400&quot;/&gt; &lt;/a&gt; &lt;a href=&quot;https://github.com/Fl4m3Ph03n1x/market_manager/workflows/build/badge.svg?branch=master&quot;&gt; &lt;img src=&quot;https://github.com/Fl4m3Ph03n1x/market_manager/workflows/build/badge.svg?branch=master&quot; alt=&quot;Build Status&quot;/&gt; &lt;/a&gt; &lt;a href=&quot;https://coveralls.io/github/Fl4m3Ph03n1x/market_manager?branch=master&quot;&gt; &lt;img src=&quot;https://coveralls.io/repos/github/Fl4m3Ph03n1x/market_manager/badge.svg?branch=master&quot; alt=&quot;Coverage Status&quot;/&gt; &lt;/a&gt;MarketManagerMakes sell requests in batch to warframe market. Used when you want to sell a lot of things or remove them from your list all at once. Specially usefull for syndicates because you dont have to buy everything in advance and if you want to avoid the 100 items limit without being a Patreon, which if you want to support the site, you should totally become.","ref":"readme.html","title":"MarketManager","type":"extras"},{"doc":"Before using this application you need to get access to two things:x-rfctoken from warframe.marketa cookie from warframe.marketTo get both of them you can:Login with your account to warframe.marketSet you status to &quot;Invisible&quot;Go to &quot;My profile&quot;Click &quot;Place order&quot; button and fill in the form, BUT DO NOT PRESS &quot;POST&quot;Using your favorite browser enter the developer's console (usually by pressing F12)Go to the network section of the developer's console, clear it (if it has previous logs) and start monitoringPress the &quot;POST&quot; button on the formThe console should have logged a POST request to the websiteInspect the request and look for &quot;Request headers&quot;Copy the cookie and the token to somewhereOnce you have the cookie and the token, you need to set the follow environment variables in your machine:MARKET_MANAGER_WM_COOKIE={cookie}MARKET_MANAGER_WM_XCSRFTOKEN={xrfctoken}Where {cookie} and {token} are the cookie and the xrfctoken you got from the website previously.","ref":"readme.html#setup","title":"MarketManager - Setup","type":"extras"},{"doc":"Place the things you want to sell under a file called products.json. This file should contain a list of objects, each one with an array of things to sell:It only supports mods currently.{ &quot;red_veil&quot;: [ { &quot;name&quot;: &quot;Gleaming Blight&quot;, &quot;id&quot;: &quot;54a74454e779892d5e5155d5&quot;, &quot;price&quot;: 15 }, { &quot;name&quot;: &quot;Eroding Blight&quot;, &quot;id&quot;: &quot;54a74454e779892d5e5155a0&quot;, &quot;price&quot;: 15 } ], &quot;new_loka&quot;: [ { &quot;name&quot;: &quot;Winds of purity&quot;, &quot;id&quot;: &quot;54a74455e779892d5e51569a&quot;, &quot;price&quot;: 15 }, { &quot;name&quot;: &quot;Disarming purity&quot;, &quot;id&quot;: &quot;5911f11d97a0add8e9d5da4c&quot;, &quot;price&quot;: 15 } ] }The format of each item is the following:{ &quot;name&quot;: &quot;Disarming purity&quot;, //name of the item &quot;id&quot;: &quot;5911f11d97a0add8e9d5da4c&quot;, //warframe.market item id &quot;price&quot;: 15, //platinum price of the item &quot;rank&quot;: 1, //rank of the mod, defaults to 0. If the mod has no rank use &quot;n/a&quot; instead &quot;quantity&quot;: 1 //number of items to sell, defaults to 1 }Once you have the products.json file set up, you can use the shell application:./market_manager --action=activate --syndicates=red_veil,new_lokaThe name of the syndicates must be the same name on the products.json file.For more information on how to use type:./market_manager -h","ref":"readme.html#usage","title":"MarketManager - Usage","type":"extras"},{"doc":"This project has a dependency erlang 22.1. While it doesn't require a lot of memory to run, it does require a lot of memory to compile, at least 4GB.Some of the dependencies also require rebar3 to work. Sometimes it is problematic to install rebar3 so, this script for Linux does the job:curl -O https://rebar3.s3.amazonaws.com/rebar3 -k rm -rf /root/.mix/rebar3 mv rebar3 /root/.mix/ mix local.rebar rebar3 /root/.mix/rebar3 --forceAfter the initial setup, the following commands are used to run the tests:mix test run all testsmix test.unit runs only unit testsmix test.integration runs only integration testsmix test.watch runs all tests continuously and re-runs them every time a file changesmix test.watch.unit runs unit tests continuously and re-runs them every time a file changesmix test.watch.integration runs integration tests continuously and re-runs them every time a file changes","ref":"readme.html#development","title":"MarketManager - Development","type":"extras"}]