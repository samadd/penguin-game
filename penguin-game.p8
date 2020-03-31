pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

_gravity_val = 0.25
_terminal_vel = 4

function destroyer_of_things(b, set)
  b.solid = false
  b.dead = true
  b.update = function() animate(b) apply_gravity(b) moving_char(b) if b.y > cam_y + 128 then del(set, b) end end
end

function player_input()
  return {left = btn(0), right = btn(1), up = btn(2), down = btn(3), fire1 = btn(4), fire2 = btn(5)}
end

function simple_mover_input(b)
  if b.vx > 0 then
    return {right = true}
  else
    return {left = true}
  end
end

function upgoer(b)
  b.y -= b.vy
end

function restricted_mover_input(x,y,d)
  if x != nil then
    return function(b)
      if b.vx > 0 then
        if b.x < x + d then return {right = true} else return {left = true} end
      else
        if b.x > x - d then return {left = true} else return {right = true} end
      end
    end
  end
  if y != nil then
    return function(b)
      if b.vy > 0 then
        if b.y < y + d then return {down = true} else return {up = true} end
      else
        if b.y > y - d then return {up = true} else return {down = true} end
      end
    end
  end
end

function chased_input(b)
  if abs(b.x - penguin.x) > 42 then return {} end
  local i = {}
  if b.y < 112 then 
    if b.x < 1012 then i.right = true else i.left = true end
  else
    if b.x > 0 then i.left = true else i.right = true end
  end
  if flr(rnd(100)) == 42 then i.fire1 = true end
  return i
end

function make_chick(x, y)
  local limit = y - 128
  local c = {x = x, y = y, height =1, width = 1, vy = 1, sprite = 6, done=false}
  c.update = function()
    upgoer(c)
    if c.y < limit then c.done = true end
  end
  return c
end

function make_heart(x, y)
  local limit = y - 128
  local h = {x = x, y = y, height =1, width = 1, vy = 1, sprite = 54, done=false}
  h.update = function()
    upgoer(h)
    if h.y < limit then h.done = true end
  end
  return h
end

function make_baddie(x, y, bg, inp)
  local b = {x = x, y = y, health = bg.health, height = bg.height, width=bg.width, vx = 0, vy = 0, accx = bg.accx, maxvx = bg.maxvx, solid = bg.solid}
  b.z_shift = bg.z_shift
  b.jump_power = bg.jump_power
  b.bounds = bg.bounds
  b.states = bg.states
  b.state = bg.states.idle
  b.sprite = b.state.frames[1]
  b.tick = 0
  b.flip = false
  b.destroy = destroyer_of_things
  b.update = function()
    local ip = inp(b)
    for f in all(bg.updaters) do
      f(b, ip)
    end
  end
  b.destroy = bg.destroy
  return b
end

function draw_platform(pf)
  local x = 0
  local y = 0
  for row in all(pf.grid) do
    for bit in all(row) do
       spr(bit, pf.x + x, pf.y + y)
       x += 8
    end
    y += 8
  end
end
function make_platform(x, y, grid, updates, inp)
  local pf = {x = x, y = y, grid = grid}
  pf.states = {idle = {modifiers = {}, precludes = {}}, walking = {modifiers = {}, precludes = {}}}
  pf.state = pf.states.idle
  pf.vx = 0
  pf.vy = 0
  pf.accx = 0.5
  pf.maxvx = 1.5
  pf.draw = function()draw_platform(pf)end
  pf.update = function()
    local ip = inp(pf)
    for f in all(updates) do
      f(pf, ip)
    end
  end
  return pf
end

function make_penguin(x, y, lives, input_func)
  local p = {x = x, y = y, lives = lives, health = 4}
  p.states = {
    idle = {frames = {0}, modifiers = {}, precludes = {}},
    walking = {frames = {0,32,32,32,0,0,0,34,34,34,0,0}, modifiers = {}, precludes = {}},
    jumping={frames = {0,2,2,2,4,4,4,0,0}, modifiers = {}, precludes = {}},
    sliding={frames = {36,36,36,52,52,52}, on_end = function() p.vy = -2 p.y = p.y - 8 end, modifiers = {height = 1, bounds = {0,15,3,7}}, precludes = {walking = true, sliding = true, jumping = true}}
    }
  p.solid = true
  p.width = 2
  p.height = 2
  p.bounds = {3,11,2,15}
  p.vx = 0
  p.vy = 0
  p.accx = 0.5
  p.jump_power = -3
  p.maxvx = 2
  p.state = p.states.idle
  p.tick = 0
  p.sprite = p.state.frames[1]
  p.flip = false
  p.rejump = true
  p.canfire = 0
  p.waitfire = 15
  p.immune = 0
  p.update = function()
    local ip = input_func()
    animate(p)
    walking_char(p, ip)
    apply_gravity(p, ip)
    jumping_char(p, ip)
    shooting_char(p, ip)
    apply_friction(p, ip)
    moving_char(p, ip)
    sliding_char(p, ip)
    p.immune = max(p.immune - 1, 0)
    end
  return p
end

function make_snowball(x,y,dir)
  local s = {x = x, y = y, vx = dir * 2.5, width = 1, height = 1, solid = true, vy = 0, accx = 1 , maxvx = 2.5}
  s.bounds = {2,6, 2, 6}
  s.states = {idle={frames = {38}, modifiers={}, precludes = {}}, walking={frames = {38}, modifiers={}, precludes = {}}}
  s.state = s.states.idle
  s.tick = 0
  s.sprite = s.state.frames[1]
  s.update = function()
    s.tick += 1
    if s.tick > 45 then destroyer_of_things(s) end
    local ip = simple_mover_input(s)
    walking_char(s, ip)
    apply_gravity(s, ip)
    apply_friction(s)
    moving_char(s)
    local hits = char_collide(s, baddies)
    if #hits > 0 then
      destroyer_of_things(s)
      destroyer_of_things(hits[1])
    end
  end
  return s
end

function get_state(thing, prop)
  if thing.state != nil and thing.state.modifiers[prop] != nil then
    return thing.state.modifiers[prop]
  else
    return thing[prop]
  end
end

function set_state(thing, new_state)
  if thing.state == thing.states[new_state] then return end
  if thing.state.on_end != nil then
    thing.state.on_end(thing)
  end
  thing.state = thing.states[new_state]
end

function apply_gravity(thing)
  thing.vy = min(thing.vy + _gravity_val, _terminal_vel)
end

function apply_friction(thing)
  local bounds = get_state(thing, 'bounds')
  local mpoint = mget((thing.x + ((bounds[1] + bounds[2]) / 2) ) / 8, (thing.y + bounds[4] + 1) / 8)
  if mpoint == 0 or thing.vx == 0 then return end
  if fget(mpoint, 1) then
    if thing.vx > 0 then thing.vx -= 0.01 else thing.vx += 0.01 end
  else
    if thing.vx > 0 then thing.vx -= 0.25 else thing.vx += 0.25 end
  end
end

function is_on_surface(thing)
  local bounds = get_state(thing, 'bounds')
  local mpoint1 = mget(((thing.x + bounds[1] + 2 ) / 8), (thing.y + bounds[4] + 1) / 8)
  local mpoint2 = mget(((thing.x + bounds[2] - 2 ) / 8), (thing.y + bounds[4] + 1) / 8)
  --local mpoint = mget((thing.x + ((thing.bounds[1] + thing.bounds[2]) / 2) ) / 8, (thing.y + thing.bounds[4] + 1) / 8)
  if fget(mpoint1, 0) or fget(mpoint2, 0) then return true else return false end
end

function hit_bad_surface(thing)
  local bounds = get_state(thing, 'bounds')
  local mpoint1 = mget(((thing.x + bounds[1] + 2 ) / 8), (thing.y + bounds[4] + 1) / 8)
  local mpoint2 = mget(((thing.x + bounds[2] - 2 ) / 8), (thing.y + bounds[4] + 1) / 8)
  --local mpoint = mget((thing.x + ((thing.bounds[1] + thing.bounds[2]) / 2) ) / 8, (thing.y + thing.bounds[4] + 1) / 8)
  if fget(mpoint1, 3) or fget(mpoint2, 3) then return true else return false end
end

function is_on_platform(thing)
  local p_width, tx1, tx2, ty
  local bounds = get_state(thing, 'bounds')
  tx1 = thing.x + bounds[1] + 1
  tx2 = thing.x + bounds[2] + 1
  ty = thing.y + bounds[4] + 1
  for platform in all(platforms) do
    p_width = #platform.grid[1] * 8
    if tx2 > platform.x and tx1 < platform.x + p_width then
      if ty >= platform.y and ty <= platform.y + 8 then
        return platform
      end
    end
  end
  return false
end

function under_surface(thing)
  local bounds = get_state(thing, 'bounds')
  local mpoint1 = mget(((thing.x + bounds[1] ) / 8), (thing.y + bounds[3] - 1) / 8)
  local mpoint2 = mget(((thing.x + bounds[2] ) / 8), (thing.y + bounds[3] - 1) / 8)
  if fget(mpoint1, 0) or fget(mpoint2, 0) then return true else return false end
end

function side_collide(thing)
  if thing.x < 0 or thing.x > 1012 then return true end
  return side_collide_left(thing) or side_collide_right(thing)
end

function side_collide_left(thing)
  local bounds = get_state(thing, 'bounds')
  local mpoint1 = mget(((thing.x + bounds[1] ) / 8), (thing.y + bounds[3]) / 8)
  local mpoint2 = mget(((thing.x + bounds[1] ) / 8), (thing.y + bounds[4]) / 8)
  return fget(mpoint1, 0) or fget(mpoint2, 0)
end
function side_collide_right(thing)
  local bounds = get_state(thing, 'bounds')
  local mpoint3 = mget(((thing.x + bounds[2] ) / 8), (thing.y + bounds[3]) / 8)
  local mpoint4 = mget(((thing.x + bounds[2] ) / 8), (thing.y + bounds[4]) / 8)
  return fget(mpoint3, 0) or fget(mpoint4, 0)
end

function checkpoint_hit(thing)
  local bounds = get_state(thing, 'bounds')
  local celx = (thing.x + ((bounds[1] + bounds[2]) / 2) ) / 8
  local cely = (thing.y + ((bounds[3] + bounds[4]) / 2) ) / 8
  local mpoint = mget(celx, cely)
  if fget(mpoint, 2) then
    mset(celx, cely, mpoint-1)
    return {celx, cely}
  else
    return false
  end
end

function collectable_hit(thing)
  local bounds = get_state(thing, 'bounds')
  local celx = (thing.x + ((bounds[1] + bounds[2]) / 2) ) / 8
  local cely = (thing.y + ((bounds[3] + bounds[4]) / 2) ) / 8
  local mpoint = mget(celx, cely)
  if mpoint == 22 then
    mset(celx, cely, nil)
    add(effects, make_chick(thing.x, thing.y))
    return true
  else
    if mpoint == 54 then
      mset(celx, cely, nil)
      penguin.health += 1
      add(effects, make_heart(thing.x, thing.y))
      return true
    end
    return false
  end
end

function char_collide(thing, group)
  local hit_things = {}
  local box_1 = get_state(thing, 'bounds')
  box_1 = {box_1[1] + thing.x, box_1[2] + thing.x, box_1[3] + thing.y, box_1[4] + thing.y}
  local box_2
  for t in all(group) do
    if not t.dead then
      box_2 = get_state(t, 'bounds')
      box_2 = {box_2[1] + t.x, box_2[2] + t.x, box_2[3] + t.y, box_2[4] + t.y}
      if box_1[1] < box_2[2] and box_1[2] > box_2[1] and box_1[3] < box_2[4] and box_1[4] > box_2[3]
      then add(hit_things, t) end
    end
  end
  return hit_things
end

function bomp_hit(a, b)
  if b.dead then return false end
  local bounds_a = get_state(a, 'bounds')
  local bounds_b = get_state(b, 'bounds')
  local point_a = a.y + bounds_a[4]
  if point_a >= b.y + bounds_b[3] and point_a < b.y + bounds_b[4] then
    return true
  else
    return false
  end
end

function walking_char(thing, input)
  if thing.state.precludes.walking then return end
  if input.left then
    thing.vx = max(thing.vx - thing.accx, -thing.maxvx)
    thing.flip = true
    if thing.vy == 0 then set_state(thing, 'walking') end
  end
  if input.right then
    thing.flip = false
    thing.vx = min(thing.vx + thing.accx, thing.maxvx)
    if thing.vy == 0 then set_state(thing, 'walking') end
  end
end

function up_and_down_char(thing, input)
  if input.up then
    thing.vy = max(thing.vy - thing.accx, -thing.maxvx)
  end
  if input.down then
    thing.vy = min(thing.vy + thing.accx, thing.maxvx)
  end
end

function jumping_char(thing, input)
  if thing.state.precludes.jumping then return end
  if input.fire1 then 
    if is_on_surface(thing) or is_on_platform(thing) != false then
      thing.rejump = true
      thing.vy = thing.jump_power
    end
    if thing.rejump and thing.vy > -0.5 and thing.vy < 0.5 then
      thing.vy = thing.jump_power
      thing.rejump = false
    end
    set_state(thing, 'jumping')
  end
end

function shooting_char(thing, input)
  thing.canfire = max(0, thing.canfire - 1)
  if thing.state.precludes.shooting then return end
  if input.fire2 and thing.canfire == 0 then
    local x, dir
    if thing.flip then x = thing.x - 2 dir = -1 else x = thing.x + 8 dir = 1 end
    add(projectiles, make_snowball(x, thing.y + 4, dir))
    thing.canfire = thing.waitfire
  end
end

function sliding_char(thing, input)
  if abs(thing.vx) < 0.5 and thing.state == thing.states.sliding then
    set_state(thing, 'idle')
  end
  if thing.state.precludes.sliding then return end
  if input.down and abs(thing.vx) > 1 and thing.vy >= 2 then
    set_state(thing, 'sliding')
    local dir = abs(thing.vx) / thing.vx
    thing.vx = dir * max(abs(thing.vx) * 1.2, thing.maxvx)
  end
end

function move_body(thing)
  thing.x += thing.vx
  thing.y += thing.vy
end

function moving_char(thing)
  local c_x = thing.x
  local c_y = thing.y
  move_body(thing)
  local platform = is_on_platform(thing)
  if thing.solid then
    if thing.vy > 0 then
      if is_on_surface(thing) or platform !=false then
        thing.vy = 0
        thing.y = c_y
        while is_on_surface(thing) == false and is_on_platform(thing) == false do
          thing.y +=1
        end
        if platform != false then
          thing.x += platform.vx
          thing.y += platform.vy
        end
      end
    else 
      if under_surface(thing) then
        thing.y = c_y
        thing.vy = -(thing.vy / 2)
      end
    end
    if thing.z_shift != true and side_collide(thing) then
      thing.x = c_x
      if side_collide_left(thing) then
        thing.x += 1
      else if side_collide_right(thing) then
        thing.x -=1 end
      end
      thing.vx = -(thing.vx * 0.25)
    end
  end
  if abs(thing.vx) < 0.12 then thing.vx = 0 end
  if thing.vx == 0 and thing.vy == 0 then
    set_state(thing, 'idle')
  end
end

function do_collisions()
  local hits = char_collide(penguin, baddies)
  local on_bad_surface = hit_bad_surface(penguin)
  local hitcount = 0
  if #hits > 0 or on_bad_surface then
    if penguin.vy > _gravity_val then
      for hit in all(hits) do
        if bomp_hit(penguin, hit) or penguin.state == penguin.states.sliding then
          hitcount += 1
          destroyer_of_things(hit, baddies)
        end
      end
    end
    if hitcount > 0 or on_bad_surface then penguin.vy = -3 end
    if penguin.immune > 0 then return end
    if hitcount < #hits or on_bad_surface then
      if penguin.health > 0 then penguin.immune = 60 penguin.health -=1
      else
        die()
      end
    end
  end
  checkpoint_hit(penguin)
  collectable_hit(penguin)
end

function animate(thing)
  thing.tick +=1
  if thing.tick > #thing.state.frames then thing.tick = 1 end
  thing.sprite = thing.state.frames[thing.tick]
end

function draw_hud()
  for i=0,penguin.health-1,1 do
    spr(54, cam_x + (i * 9), cam_y + 2)
  end
end

function draw_thing(t)
  local height = get_state(t, 'height')
  local draw = true
  if t.immune != nil and t.immune > 0 then draw = t.immune%2 == 0 end
  draw_mods(t)
  if draw then spr(t.sprite, t.x, t.y, t.width, height, t.flip) end
  pal()
end

function background_drawer(level)
  local ymax
  local y_clock
  local particles = {}
  function y_offset(pos, max)
    if pos >= max then return  pos - max else return pos end
  end
  function snow(x, y)
    x = x+ cam_x + (sin(clock.v) * 10)
    y = y_offset(y + y_clock, ymax)
    circfill(x, y, 1, 5)
    pset(x, y, 7)
  end
  function spray(density)
    local row = {}
    for i = 0, density do
      add(row, rnd(127))
    end
    return row
  end
  if level == 1 then
    ymax = 103
    return function()
      local q = flr(rnd(2))
      local row = {}
      for i = 1, q do
        row[i] = {rnd(128), 1 - rnd(2)}
      end
      if #particles == ymax then del(particles, particles[1]) end
      add(particles, row)
      rectfill(0 + cam_x,123 + cam_y, 127 + cam_x, 127 + cam_y, 7)
      rectfill(0 + cam_x,119 + cam_y, 127 + cam_x, 123 + cam_y, 12)
      rectfill(0 + cam_x,120 + cam_y, 127 + cam_x, 120 + cam_y, 7)
      rectfill(0 + cam_x,115 + cam_y, 127 + cam_x, 119 + cam_y, 1)
      rectfill(0 + cam_x,116 + cam_y, 127 + cam_x, 116 + cam_y, 12)
      rectfill(0 + cam_x,113 + cam_y, 127 + cam_x, 113 + cam_y, 1)
      circfill(99 + cam_x, 24, 8, 7)
      --fillp(0b0100000110000010.1)
      fillp(0b0101101001011010.1)
      circfill(99 + cam_x, 24, 6, 6)
      circfill(99 + cam_x, 24, 4, 5)
      fillp()
      circfill(91 + cam_x, 21, 10, 0)
      y_clock = clock.v * ymax
      local l = #particles
      for i = l, 1, -1 do
        for flake in all(particles[i]) do
          flake[1] = flake[1] + flake[2]
          snow(flake[1], l - i)
        end
      end
    end
  end
  if level == 2 then
    return function()
      local x = max(73, cam_x)
      local y
      rectfill(x, 112, 127+cam_x, 169, 12)
      rectfill(x, 176, 127+cam_x, 216, 1)
      local row
      for i = 1, 8 do
        y = 160 + i
        row = spray(i * 6)
        for particle in all(row) do
          pset(x + particle, y, 6 + flr(rnd(2)))
        end
      end
    end
  end
end

function anims_drawer(level)
  if level == 1 then
    return function()

    end
  end
  if level == 2 then
    return function()
      local m
      if flr(clock.v * 100)%5 == 0 then
        for i = 9, 127 do
          m = mget(i, 21)
          if m == 116 then mset(i, 21, 117) end
          if m == 117 then mset(i, 21, 116) end
        end
      end
    end
  end
end

function mods_drawer(level)
  if level == 2 then
    return function(thing)
      if thing.y > 168 then
        pal(1, 0)
      end
    end
  end
  return function()

  end
end

badguys = {
  crab = {
    states = {idle={frames = {78, 78, 78, 79, 79, 79}, modifiers = {}, precludes = {}}, walking={frames = {78, 78, 78, 79, 79, 79}, modifiers = {}, precludes = {}}},
    health = 1,
    updaters = {animate, walking_char, apply_gravity, apply_friction, moving_char},
    width = 1,
    height = 1,
    accx = 0.5,
    maxvx = 1.5,
    bounds = {0, 7, 3, 7},
    solid = true
  },
  brb = {
    states = {idle = {frames = {94}, modifiers = {}, precludes = {}}, walking={frames = {94}, modifiers = {}, precludes = {}}},
    health =1,
    updaters = {walking_char, moving_char},
    width = 2,
    height = 1,
    accx = 0.5,
    maxvx = 1.75,
    bounds = {0, 15, 0, 6}
  },
  panda = {
    states = {idle = {frames = {110}, modifiers = {}, precludes = {}}, walking={frames = {110}, modifiers = {}, precludes = {}}, jumping={frames = {110}, modifiers = {}, precludes = {}}},
    health = 1,
    updaters = {walking_char, jumping_char, apply_gravity, apply_friction, moving_char},
    width = 2,
    height = 2,
    accx = 0.5,
    maxvx = 2,
    jump_power = -2,
    bounds = {2, 14, 1, 15},
    z_shift = true,
    solid = true
  }
}

levels = {
  {baddies = {
    {x = 50, y= 74, t = badguys.panda, input = chased_input},
    {x = 64, y = 64, t = badguys.crab, input = simple_mover_input},
    {x = 134, y = 64, t = badguys.crab, input = simple_mover_input},
    {x = 264, y = 96, t = badguys.crab, input = simple_mover_input},
    {x = 424, y = 96, t = badguys.crab, input = simple_mover_input},
    {x = 120, y = 32, t = badguys.brb, input = restricted_mover_input(120, nil, 32)},
    {x = 128, y = 49, t = badguys.brb, input = restricted_mover_input(128, nil, 32)}
    },
    platforms = {
      {x = 851, y =72, input = restricted_mover_input(848, nil, 36), updates = {walking_char, move_body}, grid = {{64,64,64}}},
      {x = 894, y =16, input = restricted_mover_input(nil, 45, 16), updates = {up_and_down_char, move_body}, grid = {{64,64}}}
    }
  },
  {baddies = {
    {x = 992, y = 136, t = badguys.brb, input = restricted_mover_input(992, nil, 32)}
    },
    platforms = {
      
    }
  }
}

function start_game()
  penguin = make_penguin(15, -32, 5, player_input)
  level = 1
  baddies = {}
  projectiles = {}
  platforms = {}
  effects = {}
  init_level()
  cam_x = 0
  cam_y = 0
  clock = {v = 0, max = 1, inc = 0.01}
end

function init_level()
  for b in all(levels[level].baddies) do
    add(baddies, make_baddie(b.x, b.y, b.t, b.input))
  end
  for pf in all(levels[level].platforms) do
    add(platforms, make_platform(pf.x, pf.y, pf.grid, pf.updates, pf.input))
  end
  draw_background = background_drawer(level)
  do_anims = anims_drawer(level)
  draw_mods = mods_drawer(level)
end

function restart()
  penguin.x = 15
  penguin.y = -32
end

function update_game()
  penguin.update()
  for b in all(baddies) do
    b.update()
  end
  for p in all(projectiles) do
    p.update()
  end
  for pf in all(platforms) do
    pf.update()
  end
  for ef in all(effects) do
    ef.update()
    if ef.done then del(effects, ef) end
  end
  do_collisions()
  clock.v += clock.inc
  if clock.v >= clock.max then clock.v = 0 end
  if penguin.y > 128 and level == 1 then
    level = 2
    init_level()
  end
end

function focus_camera(thing)
  cam_x = min( max(thing.x - 64 + ((thing.width * 8) / 2), 0), 112 * 8)
  cam_y = max(thing.y - 82, 0)
end

function draw_game()
  cls()
  focus_camera(penguin)
  camera(cam_x,cam_y)
  do_anims()
  draw_background()
  map(0, 0, 0, 0, 128, 64)
  draw_thing(penguin)
  foreach(baddies, draw_thing)
  pal()
  foreach(projectiles, draw_thing)
  for pf in all(platforms) do
    pf.draw()
  end
  foreach(effects, draw_thing)
  draw_hud()
  --debug()
end

function die()
  for i = 0,1,0.05 do
    cls()
    draw_background()
    map(0,0,0,0,128,64)
    penguin.x -= i * 10
    penguin.y += (sin(i) * 10) + (i * 10)
    draw_thing(penguin)
    foreach(baddies, draw_thing)
    flip()
  end
  print("oh no!", 32 + cam_x, 32)
  for i = 0,30 do
    flip()
  end
  restart()
end

function debug()
  if is_on_surface(penguin) then print("is on surface!") end
end

function _init()
  start_game()
  _draw = draw_game
  _update = update_game
end

__gfx__
00000000120000000000000012000000000000001200000000051700000000000000000000000000000000000000000000000000000000000000000000000000
00000001111000000000000111100000000000016110000000067500000000000000000000000000000000000000000000000000000000000000000000000000
00000011611000000000001161100000000000111110000000156000000000000000000000000000000000000000000000000000000000000000000000000000
00000011111000000000001111990000000000111149000000155000000000000000000000000000000000000000000000000000000000000000000000000000
00000011149900000000001114940000000000111499000001115500000000000000000000000000000000000000000000000000000000000000000000000000
00000001111000000000000111100000001000011110000001156600000000000000000000000000000000000000000000000000000000000000000000000000
00000011110000000000001111000000001100111100000001556700000000000000000000000000000000000000000000000000000000000000000000000000
00000111110000000000111111000000002111111100000000456540000000000000000000000000000000000000000000000000000000000000000000000000
00001211165000000111121116500000002212111650000000055000000000000000000000000000000000000000000000000000000000000000000000000000
00012211176000000022221117600000000222111760000000566500000000000000000000000000000000000000000000000000000000000000000000000000
001221111770000000120111177000000000011117700000056ff650000000000000000000000000000000000000000000000000000000000000000000000000
001201116770000000000111677000000000011167700000566f7665000000000000000000000000000000000000000000000000000000000000000000000000
0000011167600000000001116760000000000111676000005667f665000000000000000000000000000000000000000000000000000000000000000000000000
00000111160000000000011116000000000001111600000056ff7f65000000000000000000000000000000000000000000000000000000000000000000000000
00000001100000000000000111000000000000011100000005666650000000000000000000000000000000000000000000000000000000000000000000000000
00000049994000000000049910940000000049900094000000555500000000000000000000000000000000000000000000000000000000000000000000000000
00000001200000000000000001200000000100000000120000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011110000000000000011110000000111000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000116110000000000000116110000000012111001611000566500000000000000000000000000000000000000000000000000000000000000000000000000
00000111110000000000000111110000040111111111111000677600000000000000000000000000000000000000000000000000000000000000000000000000
00000111499000000000000111499000090111167611149900677600000000000000000000000000000000000000000000000000000000000000000000000000
00000011110000000000000011110000009111777711111000566500000000000000000000000000000000000000000000000000000000000000000000000000
00000011110000000000001111000000001117777611000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111110000000000011111000000499116775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001211165000000000121116500000000000000000120028200282000000000000000000000000000000000000000000000000000000000000000000000000
0001221117600000000122111760000000011100000111108e8228e8000000000000000000000000000000000000000000000000000000000000000000000000
00122111177000000012211117700000011111111001611088e88e88000000000000000000000000000000000000000000000000000000000000000000000000
00120111677000000012011167700000000022111111111028888882000000000000000000000000000000000000000000000000000000000000000000000000
00000111676000000000011167600000000111167611149902888820000000000000000000000000000000000000000000000000000000000000000000000000
00000111160000000000011116000000499111777711111000488400000000000000000000000000000000000000000000000000000000000000000000000000
00000001100000000000000110000000001117777611000000288200000000000000000000000000000000000000000000000000000000000000000000000000
00000499094400000000449000940000499116775000000000022000000000000000000000000000000000000000000000000000000000000000000000000000
7677767777777777777676770000c677776c00000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000
676677677777777766777767000c67777776c0000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000
667c667677777777c666766600c6777777776c000000000000000000000000000000000000000000000000000000000000000000011111000000000000000000
6c666c6c777777776ccc6cc60c677777777776c00000000000000000000000000000000000000000000000000000000000000000066666500288882002888820
c6ccdccd66666666cdcdcdcc0c677777777776c00000000000000000000000000000000000000000000000000000000000000000071717602878788228878782
dccddcddccccccccdcdddcdcc67777766777776c0000000000000000000000000000000000000000000000000000000000000000059777708888888888888888
ddd1dd1dddddddddddd1ddddc677776cc677776c0000000000000000000000000000000000000000000000000000000000000000997577608282282882822828
111111111111111111111111c677776dd677776c0000000000000000000000000000000000000000000000000000000000000000006777502020020220200202
c677776c0cccccc050050505c67777766777776c1111111999999999411111110000000000000000000000000000000000000000067776500000155100000000
c677776ccc6666cc00500000c67777777777776c1111111999999999911111110000000000000000000000000000000000000000577777650015555550067600
c677776cc667766c05005005c67777777777776c1111111999999999911111110000000000000000000000000000000000000000677777760000005556771760
c677776cc677776c000500000c677777777776c011111149999999999411111100000000000000000000000000000000000000007777777725222f6666669999
c677776cc677776c505005000c666666666666c01111119999999999991111110000000000000000000000000000000000000000677777775555f666f5500494
c677776cc677776c5000050500cccccccccccc001111149999999999999111110000000000000000000000000000000000000000577777760990555550000000
c677776cc677776c00050005000dddddddddd0001149999999999999999941110000000000000000000000000000000000000000067777750900000000000000
c677776cc677776c0500505000001111111100004999999999999999999999940000000000000000000000000000000000000000056777600000000000000000
00007777777777777777700000533500002882009999999999999999000000000000000000000000000000000000000000000000000000000000001100011000
007767676767666767677700003bb300008998009999999999999999000000000000000000000000000000000000000000000000000000000000001167711000
077676766666666666767770003bb300008998004949999499994499000000000000000000000000000000000000000000000000000000000000001677770000
07676666d666d6d666676770000aa000002aa2004449444494444444000000000000000000000000000000000000000000000000000000000000000711711000
767666dddd6ddddddd66767700087000000870004444444444442244000000000000000000000000000000000000000000000000000000000000000717717000
77666dd555d55555ddd6676700078000000780002222424222422222000000000000000000000000000000000000000000000000000000000000000777770000
766ddd5555555555555d667700087000000870005522222222222222000000000000000000000000000000000000000000000000000000000000011171700000
66dd5555555555555d55d66700078000000780005552255555555555000000000000000000000000000000000000000000000000000000000000116766600000
6dd5505055050555555d5d6750505050061600000000660011111111000000000000000000000000000000000000000000000000000000000011117777760000
d0d555050055505055055dd6c0c0c0c0611111600611111611111111000000000000000000000000000000000000000000000000000000000001167777771000
dd50005500500005055055d660606060111111111111111111111111000000000000000000000000000000000000000000000000000000000000077777771100
5505000050050500050055dd70707070111111111111111111111111000000000000000000000000000000000000000000000000000000000000167777760110
d5000500500500055505055d70707070111111111111111111111111000000000000000000000000000000000000000000000000000000000001116777700000
50050005000005000500005570707070111111111111111111111111000000000000000000000000000000000000000000000000000000000001110067600000
05000000050000000005500575757575111111111111111111111111000000000000000000000000000000000000000000000000000000000011000011000000
00505050000000000500005076767676111111111111111111111111000000000000000000000000000000000000000000000000000000000000000001110000
__gff__
0000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000001030101010000000000000000000000010100010100110000000000000000000101010004111100000000000000000000000009000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043414141414141414141414416000000000000000000000000000000000000414100000000000000000000000000000000000000000000000000000000006400000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000005340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005100000000000000000000000000
0000000000000000000000000000000000000000000000000000000000414141414141414200000000000000000000000000000050000000001600000000000000000000000000000000000000000040420000000000160000000000000000000000000000000000000000000000000000005000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000041414141414400000000000000400000000000000000000000000000000000420000000000000000000000000000000000000000000000000000005000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000060614041414144000000000050000000000000005000000000000000000000000000004240000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000
0000000000004300000000000000000000000000000000000000000000000000000000000000006070525252524350000000000050000000000000005000000000000000000000000000000000000000730000000000004000000000000000000000000000000000000000000000000000005000000000000000000000000000
0000000000005000000000004341414144000000000000000000000000000000000000000000607052717171715354000000000053414141414100005000000000000000000000404000000000004341414144000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000
4240000000005000000000000000500000000000000000000000000000000000000000606161705271000016606161620000000000000000000000005000000000000000000000000000000000005000160050000000000040000000000000000000000000000000000000000000000000005000000000000000000000000000
0000000000005040000000000000500000000000000000000000000000000000000060705252527100003660705252726200000000000000000000005000000000000040400000000000000000005341000054000000000000000000000000000000006062000000000000000000000000005000000000000000000000000000
0000000000005000000000404040500000000000000000000000000000000000606170717270000000006070527171717200000000004341414141415400000000000000000000000000000000000000000000000000000000400000000000000060616272000000000000000000000000005000000000000000000000000000
0000000041415000000000000000500000000000000000000000000000000060705200000000006061617052727000000000000000005000000060616161620000000000000000000000000000000000640000000000000000000000000000006061627271000000000000000000000000005000000000000000000000000000
0000000000005000000000000016500000000000000000006061620000606170520000000000527000000000000000000000000000005000000070717171720000000000000000000000000073606161616161627300000000000000000060616162727100000073730036007373000000005000000000000000000000000000
4042404240424140414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414042404240424042404240424042414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414042440000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001664000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000
0000000000000000510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000434141440000000000000000000000000000000000000000000000000000000000000000000000000000404040000000000000000000000000000000000000000000000000000000000000
0000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000534141440000000000000000000000000000000000000000000000000000000000000000000000000000004040000000000000000000000000000000000000000000000000000000
0000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000534460616200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000070716061616200000000000000000000000000000000000000000000000000000000000000000000004040000000000000000000000000000000000000000000000000
0000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000007071717262000000000000000000000000000000000000360000000000000000000000000000000000000000000000000000000000000000000000000000000064
0000000000000000507574757475747574757475747574757475747574757475747574757475747574757475747574757475747574507475747574757475747574757475565656565775747574757475747574757475414141414141417574757475747574757475745657757475767574757475747574757475747574757456
0000000000000000507676767676767676767676767676767676767676767676767676767676767676767676767676767676767676507676767676767676767676767676656665565676767676767676767676767676767676767676767676767676767676767676765656577676767676767676767676767676767676765556
0000000000000000507676767676767676767676767676767676767676767676767676767676767676767676767676767676767676507616767676767676767676767676767676665657767676767676767676767676767676767676767676767676767676767676555656565776767676767676767676767676767676555656
0000000000000000507676767676767676767676767676767676767676767676767676767676767676767676767676767676767676534141414141414176767676767676767676766556577676767676767676767676767676767676767676767676767676767676656665665657767676767676767676767676767676565656
0000000000000000507676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767666565776767676767676767676767676767676767676767676767676767676767676765656577676767676767676767676767655565656
0000000000000000507676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676767676367676655657767616737373737373767676767676767676767676767676767676767616555656565776767676767676767676555656565656
0000656665666566656665666566656665666665666566656666656666656665666565666566656665666566666566656566656665666566656566656665656666656665666565666566656566666566656665666566666566656665666665666566656566656665666565666566656666656566666566656665666665666566
