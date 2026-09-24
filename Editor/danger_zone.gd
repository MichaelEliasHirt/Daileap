extends FoldableContainer

@onready var uid_label: Label = %UIDLabel

func update_uid_label(uid: String):
	%UIDLabel.text = uid
