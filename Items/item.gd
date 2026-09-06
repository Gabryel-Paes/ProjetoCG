class_name Item
extends Resource

enum ItemType { MEDKIT, PILLS, KEYITEM, AMMO, OTHER }

@export var item_name: String = "nome do Item"
@export var texture: Texture2D
@export_multiline var description: String = "Descrição curta do Item dizendo pra que ele serve ou algo assim"
@export var type: ItemType = ItemType.OTHER
@export var value: int = 25
@export var stackable: bool = true # Itens-chave (arma, faca, lanterna...) devem ser false
