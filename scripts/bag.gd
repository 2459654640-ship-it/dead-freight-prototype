extends RefCounted
signal changed
const ITEMS={
	"ammo":{"name":"5.56 × 45 mm","weight":.012,"value":4,"stack":120,"color":"b4a66c"},
	"med":{"name":"Field dressing","weight":.25,"value":180,"stack":3,"color":"b9c9bb"},
	"alloy":{"name":"Machined alloy","weight":1.6,"value":420,"stack":2,"color":"8babb9"},
	"circuit":{"name":"Control board","weight":.35,"value":650,"stack":2,"color":"73b1a3"},
	"drive":{"name":"Encrypted drive","weight":.2,"value":1500,"stack":1,"color":"dfb678"},
	"water":{"name":"Sealed water","weight":.7,"value":120,"stack":2,"color":"7eafce"}
}
var items:Array=[]
const CAPACITY=16
const MAX_WEIGHT=24.0
func _init(loadout:bool=true):
	if loadout:add("ammo",90);add("med",2)
func count(id:String)->int:
	var n=0
	for item in items:
		if item.id==id:n+=item.qty
	return n
func weight()->float:
	var n=0.0
	for item in items:n+=ITEMS[item.id].weight*item.qty
	return n
func value()->int:
	var n=0
	for item in items:n+=int(ITEMS[item.id].value)*item.qty
	return n
func add(id:String,qty:int=1)->int:
	if not ITEMS.has(id) or qty<=0:return 0
	var left=qty
	while left>0 and weight()+float(ITEMS[id].weight)<=MAX_WEIGHT+.0001:
		var target=-1
		for i in items.size():
			if items[i].id==id and items[i].qty<int(ITEMS[id].stack):target=i;break
		if target<0:
			if items.size()>=CAPACITY:break
			items.append({"id":id,"qty":0});target=items.size()-1
		items[target].qty+=1;left-=1
	if left!=qty:changed.emit()
	return qty-left
func remove(id:String,qty:int=1)->bool:
	if qty<=0 or count(id)<qty:return false
	var left=qty
	for i in range(items.size()-1,-1,-1):
		if items[i].id!=id:continue
		var take=mini(left,items[i].qty);items[i].qty-=take;left-=take
		if items[i].qty==0:items.remove_at(i)
		if left==0:break
	changed.emit();return true
