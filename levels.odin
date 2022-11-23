package main

char_to_tile: map[rune]Tiles = {
	'.' = .Grass,
	' ' = .Ground,
	's' = .Start,
	'e' = .End,
	'c' = .Carrot,
	'=' = .Fence,
	'x' = .Trap,
	'<' = .Belt_Left,
	'>' = .Belt_Right,
	'^' = .Belt_Up,
	'v' = .Belt_Down,
	'|' = .Wall_Left_Right,
	'-' = .Wall_Up_Down,
	'⌝' = .Wall_Right_Up,
	'⌞' = .Wall_Left_Down,
	'⌜' = .Wall_Left_Up,
	'⌟' = .Wall_Right_Down,
	'R' = .Red_Button,
	'r' = .Red_Button_Pressed,
	'Y' = .Yellow_Button,
	'y' = .Yellow_Button_Pressed,
	'k' = .Key,
	'K' = .Lock,
	'g' = .Golden_Key,
	'G' = .Golden_Lock,
	'b' = .Bronze_Key,
	'B' = .Bronze_Lock,
}

levels: [][]string = {
	{
		".........",
		"...   ...",
		".   e   .",
		". ===== .",
		". =ccc= .",
		". =ccc= .",
		". =ccc= .",
		". == == .",
		".       .",
		".   s   .",
		"...   ...",
		".........",
	},
	{
		"...........",
		"....   ....",
		".... e ....",
		".         .",
		". ===x=== .",
		". =ccccc= .",
		". =c c c= .",
		". =ccccc= .",
		". ===x=== .",
		".         .",
		"....   ....",
		".... s ....",
		"....   ....",
		"...........",
	},
	{
		".........",
		".... ....",
		"... e ...",
		".       .",
		".... ....",
		"..ccxcc..",
		"..ccxcc..",
		"..ccxcc..",
		".... ....",
		".... ....",
		"...   ...",
		"... s ...",
		"...   ...",
		".........",
	},
	{
		"..............",
		"..  =========.",
		"..  =ccc=ccc=.",
		"..  xcccxccc=.",
		"..  =ccc=ccc=.",
		"..  ======x==.",
		".   =ccc=ccc=.",
		". s xcecxccc=.",
		".   =ccc=ccc=.",
		"..  =========.",
		"..............",
	},
	{
		"...............",
		"....... .......",
		"...... e ......",
		".x           x.",
		".c.....x.....c.",
		".c.....c.....c.",
		".c...ccxcc...c.",
		".x   cc.cc   x.",
		".....ccxcc.....",
		"....... .......",
		"....... .......",
		"......   ......",
		"...... s ......",
		"......   ......",
		"...............",
	},
	{
		"...............",
		"........   ....",
		"..c  x   e ....",
		".. .....   ....",
		"..x......x.....",
		".. ..cc     cc.",
		"..c  cc === cc.",
		".....cc     cc.",
		".......x...x...",
		".......cxxxc...",
		".......x...x...",
		".   ..  ccc  ..",
		". s     cxc  ..",
		".   ..  ccc  ..",
		"...............",
	},
	{
		"...............",
		".ccc..ccc..ccc.",
		".cc xx c xx cc.",
		".c  ..   ..  c.",
		"..x....x....x..",
		"..x....x....x..",
		".c  ..   ..  c.",
		".cc xx e xx cc.",
		".c  ..   ..  c.",
		"..x....x....x..",
		"..x....x....x..",
		".   ..   ..  c.",
		". s xx c xx cc.",
		".   ..ccc..ccc.",
		"...............",
	},
	{
		"..............",
		".   ..  ......",
		". e >>  xcxcx.",
		".   ..  .xc.c.",
		".   ..  .cxcx.",
		". s <<  xxcx..",
		".   ..  ..xc..",
		"..............",
	},
	{
		"...........",
		".ccc...ccc.",
		".csc>>>ccc.",
		".ccc...ccc.",
		"..v..... ..",
		"..v..... ..",
		".   ...ccc.",
		". e xcxccc.",
		".   ...ccc.",
		"...........",
	},
	{
		".........",
		"..  e  ..",
		"..     ..",
		"..x=x=x..",
		".cc=c=cc.",
		".cc=v=cc.",
		".cc=c=cc.",
		".x==x==x.",
		".       .",
		"....^....",
		"....^....",
		"...   ...",
		"... s ...",
		"...ccc...",
		".........",
	},
	{
		"...............",
		"....cc e cc....",
		"....=== ===....",
		".x           x.",
		".c...x=x=x...c.",
		".c<<<c=c=c<<<c.",
		".c...==x==...c.",
		".x           x.",
		".....     .....",
		".......^.......",
		".......^.......",
		"......   ......",
		"...... s ......",
		"......ccc......",
		"...............",
	},
	{
		"................",
		"........ccc.....",
		"..  ....ccc   ..",
		".. x<<  ccc.. ..",
		"..  ..^..v... ..",
		"..  ..^..v... ..",
		".  x>> xccc..xx.",
		".s  ====ccc..xe.",
		".  x<< xccc..xx.",
		"..  ......... ..",
		"..  ......... ..",
		".. x>>x ccc.. ..",
		"..  ... ccc.. ..",
		"....... ccc   ..",
		"........ccc.....",
		"................",
	},
	{
		".............",
		"...... ccc ..",
		"...... ... ..",
		"...... ... ..",
		".   .. ..   .",
		". s xc|cx e .",
		".   .. ..   .",
		".. ... ......",
		".. ... ......",
		".. ccc ......",
		".............",
	},
	{
		".............",
		"......xcccx..",
		"...... ... ..",
		"...... ... ..",
		".. ccc⌝ccc ..",
		".. ... ... ..",
		".. ... ... ..",
		".   .. ..   .",
		". s xc|cx e .",
		".   .. ..   .",
		".. ... ... ..",
		".. ... ... ..",
		".. ccc⌞ccc ..",
		".............",
	},
	{
		"................",
		"......    ..ccc.",
		"......   ⌝  ccc.",
		".   .. .. ..ccc.",
		". s   ⌝.. ...v..",
		".   .....      .",
		".........  |.| .",
		"....   ..  ⌞c⌞ .",
		".... e     |.| .",
		"....   ..      .",
		"................",
	},
	{
		"................",
		".=====......y...",
		".=ccc Y.       .",
		".=ccc .. ===v==.",
		".=ccc << x<y  =.",
		".=    ..^=cccc=.",
		".==-==..^=cccc=.",
		".     ..^=cccc=.",
		". s R << =Y   =.",
		".     ..y======.",
		".. e ...........",
		"................",
	},
	{
		"..............",
		".....ccc......",
		".....c c......",
		"..... R ......",
		"......|.......",
		".cc .   .. cc.",
		".c r- s x-R c.",
		".cc .   .. cc.",
		"...x..|...x...",
		".   < x <   ..",
		". Y .ccc. e ..",
		".   .ccc.   ..",
		"..............",
	},
	{
		"................",
		"........   .....",
		"....cccB   Kccc.",
		"....ccc.. ..ccc.",
		".........r......",
		".....          .",
		".  Rr  ⌜-⌝.⌜-⌝ .",
		".=     |k⌟.⌞b| .",
		".=ccc  ⌞-----⌟ .",
		".=ccc=         .",
		".==G==..........",
		"..   ..   ......",
		".. s .. g -e....",
		"..        ......",
		"................",
	},
}
/*
⌝⌞⌜⌟
*/
