class_name CraftRecipe
extends Resource


@export var result_item: InvItem # ของที่จะได้ เช่น Axe
@export var result_amount: int = 1 # ได้กี่ชิ้น
@export var requirements: Array[CraftRequirement] # ของที่ต้องใช้
