.section .data

.global lz_resources
.type lz_resources, @object
lz_resources:
	.incbin "build/data.lzp"

#.global smd_mtekdisk
#.type smd_mtekdisk, @object
#smd_mtekdisk:
#	.incbin "data/mtekdisk.smd"
	
#.global smd_mtektext
#.type smd_mtektext, @object
#smd_mtektext:
#	.incbin "data/mtektext.smd"
	
#.global smd_star
#.type smd_star, @object
#smd_star:
#	.incbin "data/star.smd"
	
#.global smd_psn00b
#.type smd_psn00b, @object
#smd_psn00b:
#	.incbin "data/psn00blogo.smd"
	
#.global smd_scarletlogo
#.type smd_scarletlogo, @object
#smd_scarletlogo:
#	.incbin "data/scarletlogo.smd"