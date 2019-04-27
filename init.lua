local hook_tmp_throw={}
local hook_tmp_throw_timer=0
local hook_tmp_time= tonumber(minetest.settings:get("item_entity_ttl"))
hook={}
dofile(minetest.get_modpath("hook") .. "/project.lua")
dofile(minetest.get_modpath("hook") .. "/pchest.lua")
if hook_tmp_time=="" or hook_tmp_time==nil then
	hook_tmp_time=890
else
	hook_tmp_time=hook_tmp_time-10
end


slingshot_def=function(pos,n)
	if not (pos and pos.x and pos.y and pos.z and n) then return false end
	local nn=minetest.get_node(pos).name
	return (minetest.registered_nodes[nn] and minetest.registered_nodes[nn][n])
end


local function slingshot_onuse(itemstack, user)
	local veloc=15
	local pos = user:get_pos()
	local upos={x=pos.x,y=pos.y+2,z=pos.z}
	local dir = user:get_look_dir()
	local item=itemstack:to_table()
	local mode=minetest.deserialize(item["metadata"])
	if mode==nil then mode=1 else mode=mode.mode end

	local item=user:get_inventory():get_stack("main", user:get_wield_index()+mode):get_name()
	if item=="" then return itemstack end
	local e=minetest.add_item({x=pos.x,y=pos.y+2,z=pos.z},item)
	e:set_velocity({x=dir.x*veloc, y=dir.y*veloc, z=dir.z*veloc})
	e:set_acceleration({x=dir.x*-3, y=-5, z=dir.z*-3})
	e:get_luaentity().age=hook_tmp_time
	table.insert(hook_tmp_throw,{ob=e,timer=2,user=user:get_player_name()})

	if item=="hook:slingshot" then
	itemstack:set_wear(9999999)
	end

	user:get_inventory():remove_item("main", item)
	minetest.sound_play("hook_throw", {pos=pos, gain = 1.0, max_hear_distance = 5,})
	return itemstack
end



minetest.register_tool("hook:slingshot", {
	description = "Slingshot",
	range = 4,
	inventory_image = "hook_slingshot.png",
on_use=function(itemstack, user, pointed_thing)
	if pointed_thing.ref and pointed_thing.ref:is_player()==false and pointed_thing.ref:get_luaentity().name=="__builtin:item" then
		pointed_thing.ref:punch(user, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
		return itemstack
	end
	slingshot_onuse(itemstack, user)
	return itemstack
end,
on_place=function(itemstack, user, pointed_thing)
	local item=itemstack:to_table()
	local meta=minetest.deserialize(item["metadata"])
	local mode=0
	if meta==nil then meta={} mode=1 end
	if meta.mode==nil then meta.mode=1 end
	mode=(meta.mode)
	if mode==1 then
		mode=-1
		minetest.chat_send_player(user:get_player_name(), "Use stack to left")
	else
		mode=1
		minetest.chat_send_player(user:get_player_name(), "Use stack to right ")
	end
	meta.mode=mode
	item.metadata=minetest.serialize(meta)
	item.meta=minetest.serialize(meta)
	itemstack:replace(item)
	return itemstack
end

})

minetest.register_globalstep(function(dtime) 
	hook_tmp_throw_timer=hook_tmp_throw_timer+dtime
	if hook_tmp_throw_timer<0.2 then return end
	hook_tmp_throw_timer=0
	for i, t in pairs(hook_tmp_throw) do
		t.timer=t.timer-0.25
		if t.timer<=0 or t.ob==nil or t.ob:get_pos()==nil then table.remove(hook_tmp_throw,i) return end
		for ii, ob in pairs(minetest.get_objects_inside_radius(t.ob:get_pos(), 1.5)) do
			if (not ob:get_luaentity()) or (ob:get_luaentity() and (ob:get_luaentity().name~="__builtin:item")) then
				if (not ob:is_player()) or (ob:is_player() and ob:get_player_name(ob)~=t.user and minetest.setting_getbool("enable_pvp")==true) then
					ob:set_hp(ob:get_hp()-5)
					ob:punch(ob, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
					t.ob:set_velocity({x=0, y=0, z=0})
					if ob:get_hp()<=0 and ob:is_player()==false then ob:remove() end
					t.ob:set_acceleration({x=0, y=-10,z=0})
					t.ob:set_velocity({x=0, y=-10, z=0})
					table.remove(hook_tmp_throw,i)
					minetest.sound_play("hook_hard_punch", {pos=ob:get_pos(), gain = 1.0, max_hear_distance = 5,})
					break
				end
			end
		end
	end
end)

function is_hook(pos,name)
	local nname=minetest.get_node(pos).name
	if name==nil or minetest.is_protected(pos,name)==false then

		if nname=="air" or nname=="hook:rope" or
		(nname=="hook:hooking" and minetest.get_meta(pos):get_int("a")==0) then
			return true
		end
	end
	return false

end

minetest.register_tool("hook:hook", {
	description = "Hook with rope (hit a corner to climb)",
	range = 2,
	inventory_image = "hook_hook.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type~="node" then return itemstack end
		local d=minetest.dir_to_facedir(user:get_look_dir())
		local pos=pointed_thing.above
		local pos2=pointed_thing.under
		local name=user:get_player_name()

		if slingshot_def(pos2,"walkable") and
		slingshot_def({x=pos.x,y=pos.y-1,z=pos.z},"walkable")==false
		and (slingshot_def({x=pos2.x,y=pos2.y+1,z=pos2.z},"walkable")==false or minetest.get_node({x=pos2.x,y=pos2.y+1,z=pos2.z}).name=="default:snow") and
		is_hook(pos,name) and
		slingshot_def({x=pos.x,y=pos.y+1,z=pos.z},"walkable")==false then
			if d==3 then d=1
			elseif d==1 then d=3
			elseif d==2 then d=0
			elseif d==0 then d=2
			end
			if is_hook({x=pos.x,y=pos.y+1,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name = "hook:hooking",param2=d}) else return itemstack end
			if is_hook(pos,name) then minetest.set_node(pos,{name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-1,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-1,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-2,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-2,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-3,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-3,z=pos.z}, {name = "hook:rope",param2=d}) end
		end
		return itemstack
	end,
})

minetest.register_tool("hook:hook_upgrade", {
	description = "Hook with rope (double)",
	range = 5,
	inventory_image = "hook_hookup.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type~="node" then return itemstack end
		local d=minetest.dir_to_facedir(user:get_look_dir())
		local pos=pointed_thing.above
		local pos2=pointed_thing.under
		local name=user:get_player_name()
		if slingshot_def(pos2,"walkable") and
		slingshot_def({x=pos.x,y=pos.y-1,z=pos.z},"walkable")==false and
		(slingshot_def({x=pos2.x,y=pos2.y+1,z=pos2.z},"walkable")==false or minetest.get_node({x=pos2.x,y=pos2.y+1,z=pos2.z}).name=="default:snow") and
		is_hook(pos,name) and
		slingshot_def({x=pos.x,y=pos.y+1,z=pos.z},"walkable")==false then
			if d==3 then d=1
			elseif d==1 then d=3
			elseif d==2 then d=0
			elseif d==0 then d=2
			end
			if is_hook({x=pos.x,y=pos.y+1,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name = "hook:hooking",param2=d}) else return itemstack end
			if is_hook(pos,name) then minetest.set_node(pos,{name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-1,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-1,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-2,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-2,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-3,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-3,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-4,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-4,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-5,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-5,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-6,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-6,z=pos.z}, {name = "hook:rope",param2=d}) else return itemstack end
			if is_hook({x=pos.x,y=pos.y-7,z=pos.z},name) then minetest.set_node({x=pos.x,y=pos.y-7,z=pos.z}, {name = "hook:rope",param2=d}) end
		end
		return itemstack
	end,
})

minetest.register_tool("hook:climb_rope", {
	description = "Climb rope",
	range = 2,
	inventory_image = "hook_rope2.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type~="node" then
			hook.user=user
			hook.locked=false
			local pos=user:get_pos()
			local d=user:get_look_dir()
			local m=minetest.add_entity({x=pos.x,y=pos.y+1.5,z=pos.z}, "hook:power")
			m:set_velocity({x=d.x*15, y=d.y*15, z=d.z*15})
			m:set_acceleration({x=0, y=-5, z=0})
			return itemstack
		else
			local pos=pointed_thing.under
			local d=minetest.dir_to_facedir(user:get_look_dir())
			local z=0
			local x=0
			local name=user:get_player_name()
			if slingshot_def(pos,"walkable") then
				if d==0 then z=1 end
				if d==2 then z=-1 end
				if d==1 then x=1 end
				if d==3 then x=-1 end
				if is_hook({x=pos.x+x,y=pos.y,z=pos.z+z},name) and is_hook({x=pos.x+x,y=pos.y+1,z=pos.z+z},name) then
					minetest.set_node({x=pos.x+x,y=pos.y+1,z=pos.z+z},{name = "hook:hooking",param2=d})
					minetest.get_meta({x=pos.x+x,y=pos.y+1,z=pos.z+z}):set_int("a",1)
				else return itemstack end
				itemstack:take_item()
				for i=0,20,1 do
					if is_hook({x=pos.x+x,y=pos.y-i,z=pos.z+z},name) then minetest.set_node({x=pos.x+x,y=pos.y-i,z=pos.z+z},{name = "hook:rope2",param2=d}) else return itemstack end
				end
			end
			return itemstack
		end
	end,
})


minetest.register_tool("hook:climb_rope_locked", {
	description = "Climb rope (Locked)",
	range = 2,
	inventory_image = "hook_rope_locked.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type~="node" then
			hook.user=user
			hook.locked=true
			local pos=user:get_pos()
			local d=user:get_look_dir()
			local m=minetest.add_entity({x=pos.x,y=pos.y+1.5,z=pos.z}, "hook:power")
			m:set_velocity({x=d.x*15, y=d.y*15, z=d.z*15})
			m:set_acceleration({x=0, y=-5, z=0})
			return itemstack
		else
			local pos=pointed_thing.under
			local d=minetest.dir_to_facedir(user:get_look_dir())
			local z=0
			local x=0
			local name=user:get_player_name()
			if slingshot_def(pos,"walkable") then
				if d==0 then z=1 end
				if d==2 then z=-1 end
				if d==1 then x=1 end
				if d==3 then x=-1 end
				if is_hook({x=pos.x+x,y=pos.y,z=pos.z+z},name) and is_hook({x=pos.x+x,y=pos.y+1,z=pos.z+z},name) then
					minetest.set_node({x=pos.x+x,y=pos.y+1,z=pos.z+z},{name = "hook:hooking",param2=d})
					minetest.get_meta({x=pos.x+x,y=pos.y+1,z=pos.z+z}):set_int("a",1)
				else return itemstack end
				itemstack:take_item()
				for i=0,20,1 do
					if is_hook({x=pos.x+x,y=pos.y-i,z=pos.z+z},name) then
						minetest.set_node({x=pos.x+x,y=pos.y-i,z=pos.z+z},{name = "hook:rope3",param2=d})
						minetest.get_meta({x=pos.x+x,y=pos.y-i,z=pos.z+z}):set_string("owner",user:get_player_name())
					else
						return itemstack
					end
				end
			end
			return itemstack
		end
	end,
})


minetest.register_node("hook:rope", {
	description = "Rope (tempoary)",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{0, -0.5, -0.0625, 0.0625, 0.5, 0},
		}
	},
	tiles = {"hook_rope.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	drop = "",
	liquid_viscosity = 1,
	liquidtype = "source",
	liquid_alternative_flowing="hook:rope",
	liquid_alternative_source="hook:rope",
	liquid_renewable = false,
	liquid_range = 0,
	sunlight_propagates = false,
	walkable = false,
	is_ground_content = false,
	groups = {not_in_creative_inventory=1,fleshy = 3, dig_immediate = 3,},
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(3)
	end,
	on_timer = function (pos, elapsed)
		for i, ob in pairs(minetest.get_objects_inside_radius(pos, 3)) do
			if ob:is_player() then return true end
		end
		minetest.set_node(pos, {name = "air"})
		return false
	end,
})

minetest.register_node("hook:rope2", {
	description = "Rope",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{0, -0.5, -0.0625, 0.0625, 0.5, 0},
		}
	},
	tiles = {"hook_rope.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	drop = "",
	liquid_viscosity = 1,
	liquidtype = "source",
	liquid_alternative_flowing="hook:rope2",
	liquid_alternative_source="hook:rope2",
	liquid_renewable = false,
	liquid_range = 0,
	sunlight_propagates = false,
	walkable = false,
	is_ground_content = false,
	groups = {not_in_creative_inventory=1,fleshy = 3, dig_immediate = 3,},
	on_punch = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos,puncher:get_player_name()) then
			return false
		end
		puncher:get_inventory():add_item("main", ItemStack("hook:climb_rope"))
		local name=puncher:get_player_name()
		for i=0,20,1 do
			if minetest.get_node({x=pos.x,y=pos.y-i,z=pos.z}).name=="hook:rope2" or minetest.get_node({x=pos.x,y=pos.y-i,z=pos.z}).name=="air" then minetest.set_node({x=pos.x,y=pos.y-i,z=pos.z},{name = "air"}) else break end
		end
		for i=0,20,1 do
			if minetest.get_node({x=pos.x,y=pos.y+i,z=pos.z}).name=="hook:rope2" or minetest.get_node({x=pos.x,y=pos.y+i,z=pos.z}).name=="hook:hooking" or minetest.get_node({x=pos.x,y=pos.y+i,z=pos.z}).name=="air" then minetest.set_node({x=pos.x,y=pos.y+i,z=pos.z},{name = "air"}) else return false end
		end
	end,
})

minetest.register_node("hook:rope3", {
	description = "Rope (locked)",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{0, -0.5, -0.0625, 0.0625, 0.5, 0},
		}
	},
	tiles = {"hook_rope.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	drop = "",
	liquid_viscosity = 1,
	liquidtype = "source",
	liquid_alternative_flowing="hook:rope3",
	liquid_alternative_source="hook:rope3",
	liquid_renewable = false,
	liquid_range = 0,
	sunlight_propagates = false,
	walkable = false,
	is_ground_content = false,
can_dig = function(pos, player)
	if minetest.get_meta(pos):get_string("owner")~=player:get_player_name() then
		minetest.chat_send_player(player:get_player_name(), "This rope is owned by: ".. minetest.get_meta(pos):get_string("owner"))
		return false
	end
	return true
end,
	groups = {not_in_creative_inventory=1,fleshy = 3, dig_immediate = 3,},
on_punch = function(pos, node, puncher, pointed_thing)
		if minetest.get_meta(pos):get_string("owner")~=puncher:get_player_name() then
			minetest.chat_send_player(puncher:get_player_name(), "This rope is owned by: ".. minetest.get_meta(pos):get_string("owner"))
			return false
		end
		puncher:get_inventory():add_item("main", ItemStack("hook:climb_rope_locked"))
		for i=0,20,1 do
			if minetest.get_node({x=pos.x,y=pos.y-i,z=pos.z}).name=="hook:rope3" or minetest.get_node({x=pos.x,y=pos.y-i,z=pos.z}).name=="air" then minetest.set_node({x=pos.x,y=pos.y-i,z=pos.z},{name = "air"}) else break end
		end
		for i=0,20,1 do
			if minetest.get_node({x=pos.x,y=pos.y+i,z=pos.z}).name=="hook:rope3" or minetest.get_node({x=pos.x,y=pos.y+i,z=pos.z}).name=="hook:hooking" or minetest.get_node({x=pos.x,y=pos.y+i,z=pos.z}).name=="air" then minetest.set_node({x=pos.x,y=pos.y+i,z=pos.z},{name = "air"}) else return false end
		end
end,
})

minetest.register_node("hook:hooking", {
	description = "Hooking",
	drawtype = "mesh",
	mesh="hook.obj",
	tiles = {"default_stone.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable=false,
	pointable=false,
	drop = "",
	sunlight_propagates = false,
	groups = {not_in_creative_inventory=1},
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(3)

	end,
	on_timer = function (pos, elapsed)
		if minetest.get_meta(pos):get_int("a")==1 then return false end
		local r=minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name
		if r~="hook:rope" then
			minetest.set_node(pos, {name="air"})
			return false
		end
		return true
	end,
})


minetest.register_tool("hook:mba", {
	description = "Mouth breather assembly",
	range = 1,
	inventory_image = "hook_mba.png",
on_use=function(itemstack, user, pointed_thing)
	local pos=user:get_pos()
	pos.y=pos.y+1.5
	if slingshot_def(pos,"drowning")==0 then
		itemstack:set_wear(1)
	else
		local use=itemstack:get_wear()+(65536/10)
		if use<65536 then
			itemstack:set_wear(use)
			user:set_breath(11)
		end
	end
	return itemstack
end,
})

minetest.register_craft({
	output = "hook:mba",
	recipe = {
		{"","default:steel_ingot",""},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		{"default:steel_ingot","","default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "hook:hook",
	recipe = {
		{"","default:steel_ingot",""},
		{"","default:steel_ingot","default:steel_ingot"},
		{"default:steel_ingot","",""},
	}
})
minetest.register_craft({
	output = "hook:hook_upgrade",
	recipe = {
		{"","hook:hook",""},
		{"","hook:hook",""},
		{"","default:steel_ingot",""},
	}
})

minetest.register_craft({
	output = "hook:climb_rope",
	recipe = {
		{"","default:steel_ingot",""},
		{"","default:steelblock",""},
		{"","default:steel_ingot",""},
	}
})
minetest.register_craft({
	output = "hook:climb_rope_locked",
	recipe = {
		{"hook:climb_rope","default:steel_ingot",""},
	}
})

minetest.register_craft({
	output = "hook:slingshot",
	recipe = {
		{"default:steel_ingot","","default:steel_ingot"},
		{"","default:steelblock",""},
		{"","default:steel_ingot",""},
	}
})
