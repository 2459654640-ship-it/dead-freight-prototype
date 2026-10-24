extends Node
var waves:Dictionary={}
func _ready():
	var random=RandomNumberGenerator.new();random.seed=417
	for kind in ["shot","enemy","step","reload","hit","loot"]:
		var duration={"shot":.20,"enemy":.22,"step":.09,"reload":.16,"hit":.08,"loot":.18}[kind]
		var bytes=PackedByteArray();var count=int(duration*22050)
		for i in count:
			var t=float(i)/22050.0;var fade=pow(1.0-float(i)/count,3)
			var v=random.randf_range(-1,1)*.45
			if kind in ["shot","enemy"]:v=(v+sin(t*TAU*(95.0-60*t))*.7)*exp(-t*23)
			elif kind=="loot":v=sin(t*TAU*(660 if t<.09 else 880))*.16
			elif kind=="hit":v=sin(t*TAU*1400)*.16
			else:v*=.28
			var sample=int(clampf(v*fade,-1,1)*32767);bytes.append(sample&255);bytes.append((sample>>8)&255)
		var stream=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.data=bytes;waves[kind]=stream
	waves["shot"]=load("res://assets/vendor/flatguns/shot.ogg")
	waves["enemy"]=waves["shot"]
	waves["step"]=load("res://assets/vendor/flatguns/stepL1.ogg")
func play(kind:String,pos:Vector3=Vector3.ZERO,volume:float=0):
	if not waves.has(kind):return
	var p:Node
	if pos==Vector3.ZERO:p=AudioStreamPlayer.new()
	else:p=AudioStreamPlayer3D.new();p.max_distance=45;p.unit_size=4
	add_child(p)
	if p is AudioStreamPlayer3D:p.global_position=pos
	p.stream=waves[kind];p.pitch_scale=randf_range(.94,1.06) if kind in ["shot","step"] else 1.0;p.volume_db=volume;p.finished.connect(p.queue_free);p.play()
