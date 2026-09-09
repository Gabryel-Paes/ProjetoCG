class_name Item
extends Resource

enum ItemType { MEDKIT, PILLS, KEYITEM, AMMO, OTHER }

@export var item_name: String = "nome do Item"
@export var texture: Texture2D
@export_multiline var description: String = "Descrição curta do Item dizendo pra que ele serve ou algo assim"
@export var type: ItemType = ItemType.OTHER
@export var value: int = 25
## Cada item pego ocupa o próprio slot — de propósito, obriga a gerenciar
## o inventário em vez de empilhar tudo num slot só. Antes era true por
## padrão (só arma/faca/lanterna eram marcados false na mão); agora é o
## contrário: só marca true explicitamente se algum item realmente
## precisar empilhar (nenhum precisa hoje).
@export var stackable: bool = false
