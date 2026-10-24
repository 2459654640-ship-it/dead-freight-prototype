extends CanvasLayer
const Bag=preload("res://scripts/bag.gd")
var raid
var root:Control
var painter:Control
var menu:PanelContainer
var inventory:PanelContainer
var pause_menu:PanelContainer
var result:PanelContainer
var panel_open=false
var paused=false
var source:StaticBody3D
var bag_list:VBoxContainer
var loot_list:VBoxContainer
var bag_info:Label
var loot_title:Label
var status:Label
var prompt:Label
var objective:Label
var timer:Label
var notice:Label
var notice_time=0.0
var hitmark=0.0
var map_open=false
var result_title:Label
var result_body:Label
var reticle
const INK=Color("dde3d9")
const MUTED=Color("8c9e9e")
const ACCENT=Color("e6b76c")
const GREEN=Color("85c6b2")
func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	root=Control.new();add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme=Theme.new();theme.default_font_size=17;root.theme=theme
	painter=Control.new();root.add_child(painter);painter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);painter.mouse_filter=Control.MOUSE_FILTER_IGNORE;painter.draw.connect(draw_overlay)
	build_hud();build_menu();build_inventory();build_pause();build_result()
func text(parent:Node,value:String,size:int=18,color:Color=INK)->Label:
	var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);parent.add_child(l);return l
func button(parent:Node,value:String,callback:Callable,primary:bool=false)->Button:
	var b=Button.new();parent.add_child(b);b.text=value;b.custom_minimum_size=Vector2(0,44);b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;b.add_theme_font_size_override("font_size",17)
	var normal=StyleBoxFlat.new();normal.bg_color=Color("2f4244") if primary else Color("202c30");normal.border_color=Color("d2a669") if primary else Color("405153");normal.set_border_width_all(1);normal.content_margin_left=16;normal.content_margin_right=16
	b.add_theme_stylebox_override("normal",normal)
	var hover=normal.duplicate();hover.bg_color=Color("405553");hover.border_color=ACCENT;b.add_theme_stylebox_override("hover",hover)
	var pressed=hover.duplicate();pressed.bg_color=Color("52645c");b.add_theme_stylebox_override("pressed",pressed)
	b.add_theme_color_override("font_color",INK);b.pressed.connect(callback);return b
func panel(centered:bool=true,width:float=580)->PanelContainer:
	var p=PanelContainer.new();root.add_child(p)
	var style=StyleBoxFlat.new();style.bg_color=Color(.055,.085,.095,.97);style.border_color=Color("52605c");style.set_border_width_all(1);style.content_margin_left=30;style.content_margin_right=30;style.content_margin_top=28;style.content_margin_bottom=28;p.add_theme_stylebox_override("panel",style)
	if centered:p.set_anchors_and_offsets_preset(Control.PRESET_CENTER);p.offset_left=-width/2;p.offset_right=width/2;p.offset_top=-240;p.offset_bottom=240
	p.visible=false;return p
func column(parent:Node,spacing:int=12)->VBoxContainer:
	var v=VBoxContainer.new();parent.add_child(v);v.add_theme_constant_override("separation",spacing);return v
func build_hud():
	var top=MarginContainer.new();root.add_child(top);top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);top.offset_left=34;top.offset_right=-34;top.offset_top=27
	var h=HBoxContainer.new();top.add_child(h)
	var left=column(h,3);left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text(left,"D F  /  F R E I G H T   T E R M I N A L",14,ACCENT)
	objective=text(left,"NORTH GATE  /  SEARCH · SURVIVE · EXTRACT",16)
	timer=text(h,"12:00",27,INK)
	status=text(root,"",18);status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);status.offset_left=34;status.offset_top=-115;status.offset_right=500;status.offset_bottom=-40
	prompt=text(root,"",18);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER);prompt.offset_left=-300;prompt.offset_right=300;prompt.offset_top=65;prompt.offset_bottom=110
	notice=text(root,"",18,ACCENT);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);notice.offset_left=-400;notice.offset_right=400;notice.offset_top=-110;notice.offset_bottom=-60
func build_menu():
	menu=panel(false);menu.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE);menu.offset_left=56;menu.offset_right=620;menu.offset_top=65;menu.offset_bottom=-65
	var v=column(menu,15)
	text(v,"SINGLE PLAYER / EXTRACTION FPS",14,ACCENT)
	text(v,"DEAD\nFREIGHT",76,INK)
	text(v,"RAID 01   —   THE TERMINAL",19,ACCENT)
	var description=text(v,"A sealed industrial yard. Five armed scavengers.\nFind valuable freight and reach the north gate.\nWhat you carry only matters if you make it out.",18,MUTED);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var spacer=Control.new();spacer.custom_minimum_size.y=8;v.add_child(spacer)
	button(v,"DEPLOY  /  12 MINUTE RAID",func():raid.start(),true)
	text(v,"WASD  move     MOUSE  look     LMB  fire\nRMB  aim      SHIFT  sprint      CTRL  crouch\nR  reload       4  heal       F  hold to search\nTAB  backpack     M  field map     ESC  pause",16,MUTED)
	text(v,"LOADOUT  /  CARBINE · 30 + 90 ROUNDS · 2 DRESSINGS",13,ACCENT)
	text(v,"BANK  %s cr     /     %s extractions"%[raid.saved_credits,raid.saved_raids],15,GREEN)
	text(v,"Prototype · original gameplay + CC-BY licensed art\nAsset credits: assets/ATTRIBUTION.md",12,MUTED)
	menu.visible=true
func build_inventory():
	inventory=panel(true,1040);inventory.offset_top=-315;inventory.offset_bottom=315
	var v=column(inventory,14)
	var row=HBoxContainer.new();v.add_child(row)
	text(row,"FIELD INVENTORY",29).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"CLOSE  [TAB]",close_inventory)
	bag_info=text(v,"",15,ACCENT)
	var columns=HBoxContainer.new();v.add_child(columns);columns.add_theme_constant_override("separation",28);columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var a=column(columns,10);a.size_flags_horizontal=Control.SIZE_EXPAND_FILL;a.custom_minimum_size.x=450
	text(a,"YOUR BACKPACK  /  click an item to use or discard",14,MUTED)
	var scroll=ScrollContainer.new();a.add_child(scroll);scroll.custom_minimum_size.y=310;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	bag_list=column(scroll,5);bag_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var b=column(columns,10);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.x=420
	loot_title=text(b,"NO CONTAINER",14,GREEN)
	var scroll2=ScrollContainer.new();b.add_child(scroll2);scroll2.custom_minimum_size.y=310;scroll2.size_flags_vertical=Control.SIZE_EXPAND_FILL
	loot_list=column(scroll2,5);loot_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(b,"TAKE ALL",take_all,true)
	text(v,"The raid continues while searching. Find cover first.  /  16 stacks · 24 kg limit",14,MUTED)
func build_pause():
	pause_menu=panel(true,530);var v=column(pause_menu,18)
	text(v,"RAID PAUSED",35);text(v,"Your raid is safe while this menu is open.",16,MUTED)
	text(v,"MOUSE SENSITIVITY",13,ACCENT)
	var slider=HSlider.new();slider.min_value=.0007;slider.max_value=.005;slider.step=.0001;slider.value=raid.player.sensitivity;v.add_child(slider);slider.value_changed.connect(func(value):raid.player.sensitivity=value)
	button(v,"RESUME  [ESC]",toggle_pause,true)
	button(v,"RESTART RAID",restart)
	button(v,"QUIT TO DESKTOP",func():get_tree().quit())
func build_result():
	result=panel(true,670);var v=column(result,22)
	text(v,"AFTER ACTION REPORT",15,ACCENT);result_title=text(v,"EXTRACTED",46,GREEN);result_body=text(v,"",19)
	button(v,"NEW RAID",restart,true);button(v,"QUIT TO DESKTOP",func():get_tree().quit())
func show_game():
	menu.hide();toast("NORTH GATE · 12 minutes. Your backpack is only banked on extraction.")
func show_result(success:bool):
	close_inventory();result.show()
	result_title.text="SUCCESSFULLY EXTRACTED" if success else "MISSING IN ACTION"
	result_title.add_theme_color_override("font_color",GREEN if success else Color("d97d6a"))
	result_body.text="SCAVENGERS ELIMINATED    %s\nTIME IN RAID                       %02d:%02d\n%s\nTOTAL BANK                         %s cr"%[raid.kills,int(720-raid.time_left)/60,int(720-raid.time_left)%60,("CARGO SECURED                    %s cr"%raid.bag.value()) if success else "BACKPACK LOST  /  next raid gets a fresh loadout",raid.saved_credits]
func restart():
	get_tree().paused=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;get_tree().reload_current_scene()
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F11:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if not raid.active:return
		if event.keycode==KEY_ESCAPE:
			if panel_open:close_inventory()
			else:toggle_pause()
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_TAB and not paused:
			if panel_open:close_inventory()
			else:open_inventory(null)
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_M and not paused and not panel_open:map_open=not map_open
func toggle_pause():
	paused=not paused;get_tree().paused=paused;pause_menu.visible=paused;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
func open_inventory(container:StaticBody3D):
	if not raid.active:return
	source=container;panel_open=true;inventory.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;refresh_inventory();raid.sound.play("loot")
func close_inventory():
	panel_open=false;inventory.hide();source=null
	if raid.active and not paused:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func clear_children(node:Node):
	for c in node.get_children():node.remove_child(c);c.queue_free()
func refresh_inventory():
	if not is_instance_valid(bag_list) or not panel_open:return
	clear_children(bag_list);clear_children(loot_list)
	bag_info.text="CARGO   %.1f / 24.0 kg     |     %s / 16 STACKS     |     EST. VALUE  %s cr"%[raid.bag.weight(),raid.bag.items.size(),raid.bag.value()]
	for item in raid.bag.items:
		var id:String=item.id;var qty:int=item.qty;var info=Bag.ITEMS[id]
		var row=HBoxContainer.new();bag_list.add_child(row)
		var b=button(row,"%s × %s"%[info.name,qty],func():use_item(id));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_color_override("font_color",Color(info.color))
		button(row,"DROP",func():drop_item(id))
	if is_instance_valid(source):
		loot_title.text=source.get_meta("title")+"  /  click to transfer"
		for i in source.get_meta("loot").size():
			var item:Dictionary=source.get_meta("loot")[i];var info=Bag.ITEMS[item.id]
			button(loot_list,"+  %s × %s    /    %s cr"%[info.name,item.qty,int(info.value)*item.qty],func():transfer(i))
	else:loot_title.text="SEARCH CONTAINERS  /  hold F nearby"
func transfer(index:int):
	if not is_instance_valid(source):return
	var contents:Array=source.get_meta("loot")
	if index<0 or index>=contents.size():return
	var item:Dictionary=contents[index]
	var accepted=raid.bag.add(item.id,item.qty);item.qty-=accepted
	if item.qty<=0:contents.remove_at(index)
	source.set_meta("loot",contents);refresh_inventory()
	if accepted==0:toast("Backpack full · free space or reduce weight")
	else:raid.sound.play("loot",Vector3.ZERO,-9)
func take_all():
	if not is_instance_valid(source):return
	for i in range(source.get_meta("loot").size()-1,-1,-1):transfer(i)
func use_item(id:String):
	if id=="med":
		if raid.player.heal():close_inventory()
		else:toast("Cannot treat: full health or already busy")
	elif id=="water":
		if raid.bag.remove(id):raid.player.stamina=100;toast("Hydrated · stamina restored")
	else:toast("Cargo is banked when you extract")
func drop_item(id:String):
	if raid.bag.remove(id):
		raid.make_loot(raid.player.global_position+Vector3(0,.25,0)-raid.player.global_basis.z*.8,"DROPPED ITEM",[{"id":id,"qty":1}],Vector3(.3,.3,.3),Color(Bag.ITEMS[id].color))
	refresh_inventory()
func toast(value:String):
	notice_time=4;notice.text=value
func _process(delta):
	if not is_instance_valid(raid.player):return
	notice_time=maxf(0,notice_time-delta);notice.visible=notice_time>0
	hitmark=maxf(0,hitmark-delta)
	var p=raid.player
	timer.text="%02d:%02d"%[int(maxf(0,raid.time_left))/60,int(maxf(0,raid.time_left))%60]
	status.text="VITALS  %03d     /     STAMINA  %03d\nCARBINE   %02d / %03d     ·     5.56 × 45\nCARGO  %.1f kg    /    %s cr"%[int(p.health),int(p.stamina),p.magazine,raid.bag.count("ammo"),raid.bag.weight(),raid.bag.value()]
	status.visible=raid.started and not result.visible
	objective.text="NORTH GATE  /  %s m     ·     HOLD 6 s TO EXTRACT"%int(p.global_position.distance_to(raid.extract_pos)) if raid.started else "TERMINAL 02  /  OFFLINE RAID"
	prompt.text=""
	if raid.active and not panel_open and not paused:
		if p.action!="":prompt.text="%s  /  %.1f s"%[p.action,maxf(0,p.action_timer)]
		elif p.interaction_target!=null:prompt.text="[ F ]  HOLD TO SEARCH\n"+str(p.interaction_target.get_meta("title"))
		elif raid.extract_time>0:prompt.text="EXTRACTING  /  %.1f s\nStay inside the green boundary"%(6-raid.extract_time)
	painter.queue_redraw()
func draw_overlay():
	var size=painter.size;var center=size/2
	if not raid.started:
		painter.draw_rect(Rect2(Vector2.ZERO,size),Color(0,.02,.03,.2));return
	if raid.player.hurt_time>0:
		var alpha=raid.player.hurt_time*.25
		painter.draw_rect(Rect2(Vector2.ZERO,size),Color(.6,.03,.02,alpha))
	if raid.active and not panel_open and not paused:
		if not raid.player.aiming:
			var gap=5+raid.player.velocity.length()*.8+raid.player.recoil_offset*100
			for axis in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:painter.draw_line(center+axis*gap,center+axis*(gap+5),Color(.9,.94,.9,.75),1)
		else:painter.draw_circle(center,1.5,ACCENT)
		if hitmark>0:
			for dir in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:painter.draw_line(center+dir*8,center+dir*15,ACCENT,2)
		var progress=0.0
		if raid.player.action!="":progress=1-raid.player.action_timer/raid.player.action_total
		elif raid.player.interact_progress>0:progress=raid.player.interact_progress/1.2
		elif raid.extract_time>0:progress=raid.extract_time/6
		if progress>0:
			painter.draw_rect(Rect2(center+Vector2(-100,125),Vector2(200,3)),Color("273a3b"));painter.draw_rect(Rect2(center+Vector2(-100,125),Vector2(200*progress,3)),ACCENT)
	# Low profile vitality bars.
	painter.draw_rect(Rect2(Vector2(34,size.y-28),Vector2(170,4)),Color("29383b"))
	painter.draw_rect(Rect2(Vector2(34,size.y-28),Vector2(170*raid.player.health/100,4)),GREEN if raid.player.health>30 else Color("df7964"))
	painter.draw_rect(Rect2(Vector2(216,size.y-28),Vector2(120*raid.player.stamina/100,4)),ACCENT)
	if map_open and raid.active:draw_map(size)
	# Compass strip, fixed labels and moving bearing.
	if raid.active:
		var font=ThemeDB.fallback_font
		var bearing=fposmod(-rad_to_deg(raid.player.rotation.y),360)
		painter.draw_string(font,Vector2(center.x-70,40),"%03d°   /   N  ↑"%int(bearing),HORIZONTAL_ALIGNMENT_LEFT,-1,16,INK)
		painter.draw_string(font,Vector2(size.x-370,size.y-30),"TAB  BACKPACK     M  MAP     ESC  MENU",HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
func draw_map(size:Vector2):
	var origin=Vector2(size.x-360,95);var scale=4.2
	painter.draw_rect(Rect2(origin-Vector2(16,32),Vector2(326,320)),Color(.04,.08,.09,.96))
	painter.draw_string(ThemeDB.fallback_font,origin-Vector2(0,10),"FIELD MAP  /  NORTH ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,16,ACCENT)
	for r in raid.blockers:
		var pos=origin+(r.position+Vector2(35,33))*scale;painter.draw_rect(Rect2(pos,r.size*scale),Color("566563"))
	var e=origin+(Vector2(raid.extract_pos.x,raid.extract_pos.z)+Vector2(35,33))*scale
	painter.draw_circle(e,10,GREEN)
	var p=origin+(Vector2(raid.player.position.x,raid.player.position.z)+Vector2(35,33))*scale
	painter.draw_circle(p,4,ACCENT)
	var forward=Vector2(-sin(raid.player.rotation.y),-cos(raid.player.rotation.y))
	painter.draw_line(p,p+forward*12,ACCENT,2)
