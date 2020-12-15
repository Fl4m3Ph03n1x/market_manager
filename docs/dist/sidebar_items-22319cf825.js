sidebarNodes={"extras":[{"group":"","headers":[{"anchor":"modules","id":"Modules"}],"id":"api-reference","title":"API Reference"},{"group":"","headers":[{"anchor":"setup","id":"Setup"},{"anchor":"usage","id":"Usage"},{"anchor":"development","id":"Development"}],"id":"readme","title":"MarketManager"}],"modules":[{"group":"","id":"AuctionHouse","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:delete_order_response/0","id":"delete_order_response/0"},{"anchor":"t:deps/0","id":"deps/0"},{"anchor":"t:get_all_orders_response/0","id":"get_all_orders_response/0"},{"anchor":"t:item_id/0","id":"item_id/0"},{"anchor":"t:item_name/0","id":"item_name/0"},{"anchor":"t:order/0","id":"order/0"},{"anchor":"t:order_id/0","id":"order_id/0"},{"anchor":"t:order_info/0","id":"order_info/0"},{"anchor":"t:place_order_response/0","id":"place_order_response/0"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"delete_order/1","id":"delete_order/1"},{"anchor":"get_all_orders/1","id":"get_all_orders/1"},{"anchor":"place_order/1","id":"place_order/1"}]},{"key":"callbacks","name":"Callbacks","nodes":[{"anchor":"c:delete_order/1","id":"delete_order/1"},{"anchor":"c:delete_order/2","id":"delete_order/2"},{"anchor":"c:get_all_orders/1","id":"get_all_orders/1"},{"anchor":"c:get_all_orders/2","id":"get_all_orders/2"},{"anchor":"c:place_order/1","id":"place_order/1"},{"anchor":"c:place_order/2","id":"place_order/2"}]}],"sections":[],"title":"AuctionHouse"},{"group":"","id":"AuctionHouse.HTTPClient","sections":[],"title":"AuctionHouse.HTTPClient"},{"group":"","id":"AuctionHouse.Settings","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"requests_queue/0","id":"requests_queue/0"}]}],"sections":[],"title":"AuctionHouse.Settings"},{"group":"","id":"Cli","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:args/0","id":"args/0"},{"anchor":"t:dependencies/0","id":"dependencies/0"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"main/2","id":"main/2"}]}],"sections":[],"title":"Cli"},{"group":"","id":"Cli.Error","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:t/0","id":"t/0"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"new/1","id":"new/1"},{"anchor":"to_string/1","id":"to_string/1"}]}],"sections":[],"title":"Cli.Error"},{"group":"","id":"Cli.Parser","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"parse/1","id":"parse/1"}]}],"sections":[],"title":"Cli.Parser"},{"group":"","id":"Cli.Request","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:t/0","id":"t/0"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"new/1","id":"new/1"}]}],"sections":[],"title":"Cli.Request"},{"group":"","id":"Cli.Validator","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"validate/2","id":"validate/2"}]}],"sections":[],"title":"Cli.Validator"},{"group":"","id":"Manager","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:activate_response/0","id":"activate_response/0"},{"anchor":"t:deactivate_response/0","id":"deactivate_response/0"},{"anchor":"t:error_reason/0","id":"error_reason/0"},{"anchor":"t:item_id/0","id":"item_id/0"},{"anchor":"t:order_id/0","id":"order_id/0"},{"anchor":"t:strategy/0","id":"strategy/0"},{"anchor":"t:syndicate/0","id":"syndicate/0"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"activate/2","id":"activate/2"},{"anchor":"deactivate/1","id":"deactivate/1"},{"anchor":"valid_action?/1","id":"valid_action?/1"},{"anchor":"valid_strategy?/1","id":"valid_strategy?/1"},{"anchor":"valid_syndicate?/1","id":"valid_syndicate?/1"}]}],"sections":[],"title":"Manager"},{"group":"","id":"Manager.Interpreter","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:order_request/0","id":"order_request/0"},{"anchor":"t:order_request_without_rank/0","id":"order_request_without_rank/0"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"activate/3","id":"activate/3"},{"anchor":"deactivate/2","id":"deactivate/2"},{"anchor":"valid_action?/1","id":"valid_action?/1"}]}],"sections":[],"title":"Manager.Interpreter"},{"group":"","id":"Manager.PriceAnalyst","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"calculate_price/3","id":"calculate_price/3"},{"anchor":"valid_strategy?/1","id":"valid_strategy?/1"}]}],"sections":[],"title":"Manager.PriceAnalyst"},{"group":"","id":"Store","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:all_orders_store/0","id":"all_orders_store/0"},{"anchor":"t:delete_order_response/0","id":"delete_order_response/0"},{"anchor":"t:deps/0","id":"deps/0"},{"anchor":"t:error/0","id":"error/0"},{"anchor":"t:list_orders_response/0","id":"list_orders_response/0"},{"anchor":"t:list_products_response/0","id":"list_products_response/0"},{"anchor":"t:order_id/0","id":"order_id/0"},{"anchor":"t:product/0","id":"product/0"},{"anchor":"t:save_order_response/0","id":"save_order_response/0"},{"anchor":"t:syndicate/0","id":"syndicate/0"},{"anchor":"t:syndicate_exists_response/0","id":"syndicate_exists_response/0"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"delete_order/2","id":"delete_order/2"},{"anchor":"list_orders/1","id":"list_orders/1"},{"anchor":"list_products/1","id":"list_products/1"},{"anchor":"save_order/2","id":"save_order/2"},{"anchor":"syndicate_exists?/1","id":"syndicate_exists?/1"}]}],"sections":[],"title":"Store"},{"group":"","id":"Store.FileSystem","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"delete_order/3","id":"delete_order/3"},{"anchor":"list_orders/2","id":"list_orders/2"},{"anchor":"list_products/2","id":"list_products/2"},{"anchor":"save_order/3","id":"save_order/3"},{"anchor":"syndicate_exists?/2","id":"syndicate_exists?/2"}]}],"sections":[],"title":"Store.FileSystem"}],"tasks":[]}