FriendsBoxGui = FriendsBoxGui or class(TextBoxGui)
function FriendsBoxGui:init(ws, title, text, content_data, config, type)
	self._type = type
	config = config or {}
	content_data = content_data or {}
	config.h = 250
	config.w = 400
	local x, y = ws:size()
	config.x = x - config.w
	config.y = (y - config.h) - CoreMenuRenderer.Renderer.border_height + 10
	config.no_close_legend = true
	config.no_scroll_legend = true

	self._users = {}
	
	self._default_font_size = tweak_data.menu.pd2_small_font_size
	self._font = tweak_data.menu.pd2_large_font
	self._font_size = tweak_data.menu.pd2_small_font_size - 5
	self._topic_state_font_size = 22
	self._ingame_color = Color("adcc62")
	self._online_color = Color(0.6, 0.75, 1)
	self._offline_color = Color("717171")

	self._options_exists = false

	if NepgearsyMM and NepgearsyMM.Data then
		self._options_exists = true
	end

	FriendsBoxGui.super.init(self, ws, title, text, content_data, config)

	self:update_friends()
	--self:_init_steamapi_infos(Steam:userid()) -- high wip stuff
	self:set_layer(0)
end

function FriendsBoxGui:GetOption(option)
	if not NepgearsyMM and NepgearsyMM.Data then
		return false
	end

	return NepgearsyMM.Data[option]
end

function FriendsBoxGui:_init_steamapi_infos(steam_id)
	local built_link = "http://api.steampowered.com/ISteamUserStats/GetUserStatsForGame/v0002/?appid=218620&key=" .. dummy_api_key .. "&steamid=" .. tostring(steam_id)

	dohttpreq( built_link, function (data, id)
		if data then
			local table_data = {}
			for k, v in pairs(json.decode(data or {})) do
				if k then
					table_data["playerstats"]["stats"] = v
				end
			end
		end
	end)
end

function FriendsBoxGui:_create_text_box(ws, title, text, content_data, config)
    FriendsBoxGui.super._create_text_box(self, ws, title, text, content_data, config)
 	
 	if BeardLib then
 		self._scroll = ScrollablePanelModified:new(self._panel, "scrollable_panel", {
	        layer = 20, 
	        padding = 2, 
	        scroll_width = 6, 
	        hide_shade = true, 
	        color = Color.white
	    })
 	else
		self._scroll = ScrollablePanel:new(self._panel, "scrollable_panel", {layer = 20})
	end

	self._canvas = self._scroll:canvas()

    local friends_panel = self._scroll_panel:panel({
        h = 600,
        name = "friends_panel",
        x = 0,
        layer = 1
    }) 
    self._friends_panel = friends_panel
    local ingame_panel = self._canvas:panel({
        h = 100,
        name = "ingame_panel",
        x = 0,
        layer = 0
    })
    self._ingame_panel = ingame_panel
    local online_panel = self._canvas:panel({
        h = 100,
        name = "online_panel",
        x = 0,
        layer = 0
    })
    self._online_panel = online_panel
    local offline_panel = self._canvas:panel({
        h = 100,
        name = "offline_panel",
        x = 0,
        layer = 0
    })
    self._offline_panel = offline_panel
    local h = 0
    local ingame_text = self._canvas:text({
        vertical = "center",
        name = "ingame_text",
        hvertical = "center",
        align = "left",
        halign = "left",
        text = managers.localization:text("menu_ingame"),
        font = self._font,
        font_size = self._topic_state_font_size,
        y = h,
        color = Color(0.75, 0.75, 0.75)
    })
    local _, _, tw, th = ingame_text:text_rect()
 
    ingame_text:set_size(tw, th)
 
    h = h + th
    local online_text = self._canvas:text({
        vertical = "center",
        name = "online_text",
        hvertical = "center",
        align = "left",
        halign = "left",
        text = managers.localization:text("menu_online"),
        font = self._font,
        font_size = self._topic_state_font_size,
        y = h,
        color = Color(0.75, 0.75, 0.75)
    })
    local _, _, tw, th = online_text:text_rect()
 
    online_text:set_size(tw, th)
 
    h = h + th
    local offline_text = self._canvas:text({
        vertical = "center",
        name = "offline_text",
        hvertical = "center",
        align = "left",
        halign = "left",
        text = managers.localization:text("menu_offline"),
        font = self._font,
        font_size = self._topic_state_font_size,
        y = h,
        color = Color(0.75, 0.75, 0.75)
    })
    local _, _, tw, th = offline_text:text_rect()
 
    offline_text:set_size(tw, th)
 
    h = h + th
 
    --friends_panel:set_h(h)
    --self._scroll_panel:set_h(math.max(self._scroll_panel:h(), friends_panel:h()))
    self:_set_scroll_indicator()
    self:_layout_friends_panel()
    self._scroll:update_canvas_size()
end

function FriendsBoxGui:_layout_friends_panel()
    local friends_panel = self._scroll_panel:child("friends_panel")
    self._scroll_panel:set_h(math.max(self._scroll_panel:h(), friends_panel:h()))
    local panels = {}
    for _, user in pairs(self._users) do
        if alive(user.panel) then
            table.insert(panels, {panel = user.panel, state = user.main_state, username = user.user:name()})
        end
    end
    local order = {ingame = 1, online = 2, away = 3, busy = 3, snooze = 3, offline = 4}
    table.sort(panels, function(a,b)
        if not a.state then
            return false
        end
        local ia = order[a.state] or 2
        local ib = order[b.state] or 2

        local a_username = tostring(a.username)
    	local b_username = tostring(b.username)

        return ia < ib or (ia == ib and a.username < b.username)
    end)

    local prev
    for _, user in pairs(panels) do
        local panel = user.panel
        if prev then
            panel:set_y(prev:bottom() + 2)
        else
            panel:set_y(0)
        end
        prev = panel
    end
    self._scroll:update_canvas_size()
    self:_set_scroll_indicator()
    self:_check_scroll_indicator_states()
end

function FriendsBoxGui:_create_user(h, user, state, sub_state, level, is_in_lobby)
	local color = state == "online" and self._online_color or state == "ingame" and self._ingame_color or self._offline_color
	local panel = self._canvas:panel({
		layer = 0,
		name = user:id(),
	})

	if level == "" or nil then
		level = "???"
	end

	local bg_rect = panel:rect({
		name = "background",
		color = Color.white,
		alpha = 0.1,
		layer = -1,
		halign = "scale",
		valign = "scale"
	})
	local blur = panel:bitmap({
		texture = "guis/textures/test_blur_df",
		w = panel:w(),
		h = panel:h(),
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	local avatar = panel:bitmap({
		name = "avatar",
		w = 33,
		h = 33,
		x = 5,
		y = 3,
		texture = "guis/textures/pd2/none_icon"
	})

	Steam:friend_avatar(2, user:id(), function (texture)
		texture = texture or "guis/textures/pd2/none_icon"
		avatar:set_image(texture)
	end)

	local user_name = panel:text({
		name = "user_name",
		vertical = "center",
		hvertical = "center",
		halign = "left",
		text = user:name(),
		font = self._font,
		font_size = self._default_font_size,
		x = 6 + avatar:right(),
		y = 3,
		color = color
	})
	local _, _, tw, th = user_name:text_rect()

	user_name:set_size(tw, th)

	local user_level = panel:text({
		name = "user_level",
		vertical = "center",
		hvertical = "center",
		align = "left",
		halign = "left",
		text = "REP " .. level,
		font = self._font,
		font_size = self._default_font_size,
		y = math.round(0),
		x = 6 + avatar:right(),
		color = Color(0.5, 0.5, 0.5),
		visible = state == "ingame" and self:GetOption("NepgearsyMM_FriendList_EnableRepLevel_Value") == true
	})
	local _, _, sw, sh = user_level:text_rect()
	user_level:set_size(sw, sh)
	user_level:set_center_y(math.round(user_name:center_y()))

	self:_make_fine_text(user_level)

	local is_user_level_visible = user_level:visible()
	user_name:set_x(is_user_level_visible and 10 + user_level:right() or 6 + avatar:right())

	local user_state = panel:text({
		name = "user_state",
		vertical = "center",
		hvertical = "center",
		halign = "left",
		text = string.upper(sub_state),
		font = self._font,
		font_size = self._font_size - 2,
		x = 6 + avatar:right(),
		y = math.round(0 + th) + 5,
		color = color,
		visible = state ~= "offline"
	})
	local _, _, sw, sh = user_state:text_rect()

	user_state:set_size(sw, sh)
	panel:set_h(th + sh + 6)
	panel:rect({
		name = "marker_rect",
		visible = false,
		layer = -1,
		color = Color(0, 0.5, 0.5, 0.5)
	})

	local texture, rect = tweak_data.hud_icons:get_icon_data("icon_equipped")
	local arrow = panel:bitmap({
		name = "arrow",
		layer = 0,
		visible = false,
		texture = texture,
		texture_rect = rect,
		x = avatar:right()
	})

	arrow:set_center_y(user_name:center_y())

	local texture, rect = tweak_data.hud_icons:get_icon_data("icon_addon")
	local lobby = panel:bitmap({
		name = "lobby",
		layer = 0,
		visible = false,
		texture = texture,
		texture_rect = rect
	})

	lobby:set_center_y(user_state:center_y())
	lobby:set_right(panel:w())

	local button_join = panel:panel({
		name = "button_join_" .. user:id(),
		layer = 1,
		w = 33,
		h = 33,
		visible = false
	})

	button_join:set_right(math.floor(panel:w()) - 5)
	button_join:set_center_y(math.round(panel:center_y()))

	local button_join_bg = button_join:rect({
		name = "background",
		color = Color.black,
		alpha = 0.4,
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	local button_join_t = button_join:text({
		font = self._font,
		font_size = self._font_size + 6,
		text = "J",
		color = Color.white,
		valign = "center",
		align = "center",
		vertical = "center",
		alpha = is_in_lobby and 1 or 0.4
	})

	return panel
end

function FriendsBoxGui:update_friends()
	if not Steam:logged_on() then
		return
	end

	local friends = Steam:friends() or {}
	
	for _, user in pairs(friends) do
		local main_state, sub_state = nil
		local state = user:state()
		local rich_presence_status = user:rich_presence("status")
		local rich_presence_level = user:rich_presence("level")
		local payday1 = rich_presence_level == ""
		local playing_this = user:playing_this()

		local s = string.find(rich_presence_status, "\n")

		if s then
			rich_presence_status = string.gsub(rich_presence_status, "(\n)", ", ")
		end

		if playing_this then
			main_state = "ingame"

			if state == "invalid" then
				state = managers.localization:text("nepmenu_friendlist_status_ltp")
			end

			sub_state = managers.localization:text("nepmenu_friendlist_status_ingame", {state = state})
		elseif state == "online" or state == "away" or state == "busy" or state == "snooze" or state == "invalid" then

			if state == "invalid" then
				state = managers.localization:text("nepmenu_friendlist_status_ltp")
			end

			main_state = "online"
			sub_state = state
		else
			main_state = state
			sub_state = state
		end

		if user:lobby() and rich_presence_status ~= "" then
			--local numbers = managers.network.matchmake:_lobby_to_numbers(user:lobby())
			sub_state = rich_presence_status or managers.localization:text("nepmenu_friendlist_status_ingame_joinable")
		elseif rich_presence_status == "" then
			if main_state == "ingame" then
				-- Nothing
			elseif main_state == "offline" then
				-- Nothing
			end
		else
			sub_state = managers.localization:text("nepmenu_friendlist_status_ingame_not_joinable")
		end

		self._users[user:id()] = self._users[user:id()] or {}
		local user_tbl = self._users[user:id()]
		user_tbl.user = user
		user_tbl.main_state = main_state
		user_tbl.sub_state = sub_state
		user_tbl.lobby = user:lobby()
		user_tbl.level = rich_presence_level
		user_tbl.payday1 = payday1
	end

	self._canvas:clear()

	for _, user in pairs(self._users) do
		user.panel = nil
		if user.main_state == "ingame" then
			user.panel = self:_create_user(0, user.user, "ingame", user.sub_state, user.level, user.lobby)
		elseif user.main_state == "online" then
			user.panel = self:_create_user(0, user.user, "online", user.sub_state, user.level, user.lobby)
		else
			user.panel = self:_create_user(0, user.user, "offline", user.sub_state, user.level, user.lobby)
		end
	end

	self:_layout_friends_panel()
end

function FriendsBoxGui:_get_user_panel(id)
    return self._canvas:child(id)
end

function FriendsBoxGui:_inside_user(x, y)
	for _, user_panel in ipairs(self._canvas:children()) do
		if user_panel:inside(x, y) then
			return user_panel
		end
	end

	return nil
end

function FriendsBoxGui:mouse_clicked( o, button, x, y )
	if alive(self._scroll) then
		return self._scroll:mouse_clicked( o, button, x, y )
	end
end

function FriendsBoxGui:mouse_pressed(button, x, y)
	if self._friend_action_gui and self._friend_action_gui:visible() and self._friend_action_gui:in_info_area_focus(x, y) then
		if button == Idstring("0") or button == Idstring("1") or button == Idstring("2") then
			local focus_btn_id = self._friend_action_gui:get_focus_button_id()

			print("get_focus_button_id()", focus_btn_id)

			if focus_btn_id == "join_game" then
				print(" join game ", self._friend_action_user, self._friend_action_user:lobby())

				if self._friend_action_user:lobby() then
					managers.network.matchmake:join_server_with_check(self._friend_action_user:lobby():id())
				end
			elseif focus_btn_id == "message" then
				self._friend_action_user:open_overlay("chat")
			elseif focus_btn_id == "view_profile" then
				self._friend_action_user:open_overlay("steamid")
			elseif focus_btn_id == "view_achievements" then
				self._friend_action_user:open_overlay("achievements")
			elseif focus_btn_id == "view_stats" then
				self._friend_action_user:open_overlay("stats")
			elseif focus_btn_id == "view_character" then
			elseif focus_btn_id == "invite" then
				print("send invite")

				if managers.network.matchmake.lobby_handler then
					self._friend_action_user:invite(managers.network.matchmake.lobby_handler:id())
				end
			end

			self:_hide_friend_action_user()
		end

		return true
	end

	if self:in_info_area_focus(x, y) and button == Idstring("0") then
		local result
		if button == Idstring("0") then
			if self._scroll:mouse_pressed(button, x, y) then
				return true
			end
		elseif button == Idstring("mouse wheel down") and self._scroll:is_scrollable() then
			if self._scroll:scroll(x, y, -1) then
				return true
			end
		elseif button == Idstring("mouse wheel up")  and self._scroll:is_scrollable() then
			if self._scroll:scroll(x, y, 1) then
				return true
			end
		end

		local user_panel = self:_inside_user(x, y)
		if user_panel then
			if self._users[user_panel:name()].lobby then
				managers.menu_component:criment_goto_lobby(self._users[user_panel:name()].lobby)
			end

			if self._friend_action_user ~= self._users[user_panel:name()].user then
				self._friend_action_user = self._users[user_panel:name()].user

				self:_create_friend_action_gui_by_user(self._users[user_panel:name()])

				x = x + 16
				y = y - 16

				--if (self:x() + self:w()) - 20 < x + self._friend_action_gui:w() then
				--	x = ((self:x() + self:w()) - 20) - self._friend_action_gui:w()
				--end

				--if self:y() + self:h() < y + self._friend_action_gui:h() then
				--	y = (self:y() + self:h()) - self._friend_action_gui:h()
				--end

				self._friend_action_gui:set_position(x, y)
			else
				self:_hide_friend_action_user()
			end

			return true
		end
	end
	self:_hide_friend_action_user()

	return result
end

function FriendsBoxGui:mouse_moved(x, y)
	if self._friend_action_gui and self._friend_action_gui:visible() and self._friend_action_gui:in_info_area_focus(x, y) then
		self._friend_action_gui:check_focus_button(x, y)
		return
	end

	local _, pointer = self._scroll:mouse_moved(nil, x, y) 
    if pointer then
        if managers.mouse_pointer.set_pointer_image then
            managers.mouse_pointer:set_pointer_image(pointer)
        end
        return true
    else
        if managers.mouse_pointer.set_pointer_image then
            managers.mouse_pointer:set_pointer_image("arrow")
        end
	end
end

function FriendsBoxGui:mouse_released(o, button, x, y)
	self._scroll:mouse_released(button, x, y)
end

function FriendsBoxGui:mouse_wheel_up( x, y )
	self._scroll:scroll(x, y, 1)
end

function FriendsBoxGui:mouse_wheel_down( x, y )
	self._scroll:scroll(x, y, -1)
end

function FriendsBoxGui:set_size(x, y)
	FriendsBoxGui.super.set_size(self, x, y)
	local friends_panel = self._scroll_panel:child("friends_panel")
	friends_panel:set_w(self._scroll_panel:w())

	for _, user_panel in ipairs(self._canvas:children()) do
		--user_panel:set_w(friends_panel:w())
		user_panel:child("lobby"):set_right(user_panel:w())
	end
end

function FriendsBoxGui:_create_friend_action_gui_by_user(user_data)
	if self._friend_action_gui then
		self._friend_action_gui:close()
	end

	local user = user_data.user
	local offline = user_data.main_state == "offline"
	local data = {button_list = {}}
	local my_lobby_id = managers.network.matchmake.lobby_handler and managers.network.matchmake.lobby_handler:id()
	local user_lobby_id = user:lobby() and user:lobby():id()

	if not my_lobby_id and user_lobby_id and not user_data.payday1 and not Global.game_settings.single_player then
		local join_game = {
			text = managers.localization:text("nepmenu_friendlist_button_join_game"),
			id_name = "join_game"
		}

		table.insert(data.button_list, join_game)
	end

	if not offline and managers.network.matchmake.lobby_handler and not user_lobby_id then
		local invite = {
			text = managers.localization:text("nepmenu_friendlist_button_invite"),
			id_name = "invite"
		}

		table.insert(data.button_list, invite)
	end

	local chat_button = {
		text = managers.localization:text("nepmenu_friendlist_button_send_message"),
		id_name = "message"
	}

	table.insert(data.button_list, chat_button)

	local profile_button = {
		text = managers.localization:text("nepmenu_friendlist_button_view_profile"),
		id_name = "view_profile"
	}

	table.insert(data.button_list, profile_button)

	local achievements_button = {
		text = managers.localization:text("nepmenu_friendlist_button_view_achievements"),
		id_name = "view_achievements"
	}

	table.insert(data.button_list, achievements_button)

	data.focus_button = 1
	self._friend_action_gui = TextBoxGui:new(self._ws, nil, nil, data, {
		title = "Actions",
		--only_buttons = true,
		no_close_legend = true,
		forced_h = true,
		use_indicator = false,
		y = 0,
		w = 200,
		x = 0,
		h = 0
	})

	self._friend_action_gui:set_layer(self:layer() + 200)
end

function FriendsBoxGui:_make_fine_text(text)
	local x, y, w, h = text:text_rect()
	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end