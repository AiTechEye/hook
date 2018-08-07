minetest.register_entity("hook:power",{
	hp_max = 100,
	physical = true,
	weight = 0,
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	visual = "upright_sprite",
	visual_size = {x=1, y=1},
	textures = {"hook_hooking.png"},
	spritediv = {x=1, y=1},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
	timer2=0,
	d=0,
	uname="",
	locked=false,
on_activate=function(self, staticdata)
	if hook.user==nil then
		self.object:remove()
		return self
	end
	self.d=hook.user:get_look_dir()
	self.fd=minetest.dir_to_facedir(self.d)
	self.uname=hook.user:get_player_name()
	self.user=hook.user
	self.locked=hook.locked
	hook.user=nil
	if self.fd==3 then self.fd=1
	elseif self.fd==1 then self.fd=3
	elseif self.fd==2 then self.fd=0
	elseif self.fd==0 then self.fd=2
	end
	end,
on_step= function(self, dtime)
	self.timer2=self.timer2+dtime
	local pos=self.object:getpos()
	local kill=0
	if minetest.registered_nodes[minetest.get_node({x=pos.x+self.d.x,y=pos.y,z=pos.z+self.d.z}).name].walkable and minetest.registered_nodes[minetest.get_node({x=pos.x+self.d.x,y=pos.y+1,z=pos.z+self.d.z}).name].walkable==false and is_hook(pos,self.uname) and is_hook({x=pos.x,y=pos.y+1,z=pos.z},self.uname) then
		kill=1
		if self.locked then
			if self.user:get_inventory():contains_item("main", "hook:climb_rope_locked")==false then
				self.object:set_hp(0)
				self.object:punch(self.object, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
				return self
			end
			if is_hook({x=pos.x,y=pos.y+1,z=pos.z},self.uname) then
				minetest.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name = "hook:hooking",param2=self.fd})
				minetest.get_meta({x=pos.x,y=pos.y+1,z=pos.z}):set_int("a",1)
			else
				return self
			end
			self.user:get_inventory():remove_item("main", "hook:climb_rope_locked")
			for i=0,20,1 do
				if is_hook({x=pos.x,y=pos.y-i,z=pos.z},self.uname) then minetest.set_node({x=pos.x,y=pos.y-i,z=pos.z},{name = "hook:rope3",param2=self.fd}) else break end
				minetest.get_meta({x=pos.x,y=pos.y-i,z=pos.z}):set_string("owner",self.uname)
			end
		else
			if self.user:get_inventory():contains_item("main", "hook:climb_rope")==false then
				self.object:set_hp(0)
				self.object:punch(self.object, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)
				return self
			end
			if is_hook({x=pos.x,y=pos.y+1,z=pos.z},self.uname) then
				minetest.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name = "hook:hooking",param2=self.fd})
				minetest.get_meta({x=pos.x,y=pos.y+1,z=pos.z}):set_int("a",1)
			else
				return self
			end
			self.user:get_inventory():remove_item("main", "hook:climb_rope")
			for i=0,20,1 do
				if is_hook({x=pos.x,y=pos.y-i,z=pos.z},self.uname) then minetest.set_node({x=pos.x,y=pos.y-i,z=pos.z},{name = "hook:rope2",param2=self.fd}) else break end
			end
		end
	end
	if self.timer2>3 or kill==1 then
		self.object:set_hp(0)
		self.object:punch(self.object, {full_punch_interval=1.0,damage_groups={fleshy=4}}, "default:bronze_pick", nil)

	end
	return self
end,
})