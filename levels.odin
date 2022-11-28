package main

char_to_tile: map[rune]Tiles = {
	'.' = .Grass,
	' ' = .Ground,
	'@' = .Start,
	'o' = .End,
	'*' = .Carrot,
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
	's' = .Silver_Key,
	'S' = .Silver_Lock,
	'g' = .Golden_Key,
	'G' = .Golden_Lock,
	'c' = .Copper_Key,
	'C' = .Copper_Lock,
}

levels := [?][]string {
	{
		".........",
		"...   ...",
		".   o   .",
		". ===== .",
		". =***= .",
		". =***= .",
		". =***= .",
		". == == .",
		".       .",
		".   @   .",
		"...   ...",
		".........",
	},
	{
		"...........",
		"....   ....",
		".... o ....",
		".         .",
		". ===x=== .",
		". =*****= .",
		". =* * *= .",
		". =*****= .",
		". ===x=== .",
		".         .",
		"....   ....",
		".... @ ....",
		"....   ....",
		"...........",
	},
	{
		".........",
		".... ....",
		"... o ...",
		".       .",
		".... ....",
		"..**x**..",
		"..**x**..",
		"..**x**..",
		".... ....",
		".... ....",
		"...   ...",
		"... @ ...",
		"...   ...",
		".........",
	},
	{
		"..............",
		"..  =========.",
		"..  =***=***=.",
		"..  x***x***=.",
		"..  =***=***=.",
		"..  ======x==.",
		".   =***=***=.",
		". @ x*o*x***=.",
		".   =***=***=.",
		"..  =========.",
		"..............",
	},
	{
		"...............",
		"....... .......",
		"...... o ......",
		".x           x.",
		".*.....x.....*.",
		".*.....*.....*.",
		".*...**x**...*.",
		".x   **.**   x.",
		".....**x**.....",
		"....... .......",
		"....... .......",
		"......   ......",
		"...... @ ......",
		"......   ......",
		"...............",
	},
	{
		"...............",
		"........   ....",
		"..*  x   o ....",
		".. .....   ....",
		"..x......x.....",
		".. ..**     **.",
		"..*  ** === **.",
		".....**     **.",
		".......x...x...",
		".......*xxx*...",
		".......x...x...",
		".   ..  ***  ..",
		". @     *x*  ..",
		".   ..  ***  ..",
		"...............",
	},
	{
		"...............",
		".***..***..***.",
		".** xx * xx **.",
		".*  ..   ..  *.",
		"..x....x....x..",
		"..x....x....x..",
		".*  ..   ..  *.",
		".** xx o xx **.",
		".*  ..   ..  *.",
		"..x....x....x..",
		"..x....x....x..",
		".   ..   ..  *.",
		". @ xx * xx **.",
		".   ..***..***.",
		"...............",
	},
	{
		"..............",
		".   ..  ......",
		". o >>  x*x*x.",
		".   ..  .x*.*.",
		".   ..  .*x*x.",
		". @ <<  xx*x..",
		".   ..  ..x*..",
		"..............",
	},
	{
		"...........",
		".***...***.",
		".*@*>>>***.",
		".***...***.",
		"..v..... ..",
		"..v..... ..",
		".   ...***.",
		". o x*x***.",
		".   ...***.",
		"...........",
	},
	{
		".........",
		"..  o  ..",
		"..     ..",
		"..x=x=x..",
		".**=*=**.",
		".**=v=**.",
		".**=*=**.",
		".x==x==x.",
		".       .",
		"....^....",
		"....^....",
		"...   ...",
		"... @ ...",
		"...***...",
		".........",
	},
	{
		"...............",
		"....** o **....",
		"....=== ===....",
		".x           x.",
		".*...x=x=x...*.",
		".*<<<*=*=*<<<*.",
		".*...==x==...*.",
		".x           x.",
		".....     .....",
		".......^.......",
		".......^.......",
		"......   ......",
		"...... @ ......",
		"......***......",
		"...............",
	},
	{
		"................",
		"........***.....",
		"..  ....***   ..",
		".. x<<  ***.. ..",
		"..  ..^..v... ..",
		"..  ..^..v... ..",
		".  x>> x***..xx.",
		".@  ====***..xo.",
		".  x<< x***..xx.",
		"..  ......... ..",
		"..  ......... ..",
		".. x>>x ***.. ..",
		"..  ... ***.. ..",
		"....... ***   ..",
		"........***.....",
		"................",
	},
	{
		".............",
		"...... *** ..",
		"...... ... ..",
		"...... ... ..",
		".   .. ..   .",
		". @ x*|*x o .",
		".   .. ..   .",
		".. ... ......",
		".. ... ......",
		".. *** ......",
		".............",
	},
	{
		".............",
		"......x***x..",
		"...... ... ..",
		"...... ... ..",
		".. ***⌝*** ..",
		".. ... ... ..",
		".. ... ... ..",
		".   .. ..   .",
		". @ x*|*x o .",
		".   .. ..   .",
		".. ... ... ..",
		".. ... ... ..",
		".. ***⌞*** ..",
		".............",
	},
	{
		"................",
		"......    ..***.",
		"......   ⌝  ***.",
		".   .. .. ..***.",
		". @   ⌝.. ...v..",
		".   .....      .",
		".........  |.| .",
		"....   ..  ⌞*⌞ .",
		".... o     |.| .",
		"....   ..      .",
		"................",
	},
	{
		"................",
		".=====......y...",
		".=*** Y.       .",
		".=*** .. ===v==.",
		".=*** << x<y  =.",
		".=    ..^=****=.",
		".==-==..^=****=.",
		".     ..^=****=.",
		". @ R << =Y   =.",
		".     ..y======.",
		".. o ...........",
		"................",
	},
	{
		"..............",
		".....***......",
		".....* *......",
		"..... R ......",
		"......|.......",
		".** .   .. **.",
		".* r- @ x-R *.",
		".** .   .. **.",
		"...x..|...x...",
		".   < x <   ..",
		". Y .***. o ..",
		".   .***.   ..",
		"..............",
	},
	{
		"................",
		"........   .....",
		"....***C   S***.",
		"....***.. ..***.",
		".........r......",
		".....          .",
		".  Rr  ⌜-⌝.⌜-⌝ .",
		".=     |s⌟.⌞c| .",
		".=***  ⌞-----⌟ .",
		".=***=         .",
		".==G==..........",
		"..   ..   ......",
		".. @ .. g -o....",
		"..        ......",
		"................",
	},
	{
		"...............",
		"..........⌜--⌝.",
		"..........|Rr|.",
		"..........|**|.",
		"..........⌞-⌟|.",
		"..x*x*x ⌝....|.",
		"..|. . .|....|.",
		".@ *x*x |    ⌟.",
		"..|. . .|.. ==.",
		"..x*x*x ⌟..   .",
		"........... o .",
		"...........   .",
		"...............",
	},
	{
		".........",
		".x**x**x.",
		".*.. ..*.",
		".*.. ..s.",
		".x**S**C.",
		".*.. ..*.",
		".*.. ..*.",
		".c**x**x.",
		".*.. ..*.",
		".*.. ..*.",
		".x  @  x.",
		".... ....",
		"....o....",
		".........",
	},
	{
		"...............",
		".         xxxx.",
		".         =v=*.",
		". ------- =*=*.",
		". =*=R=y= =*=*.",
		". =*=*=*= =*=*.",
		". =*=*=*= =*=^.",
		". =*<*<*= xxxx.",
		". ======= xxxx.",
		".    Y    ====.",
		".@        - o .",
		"...............",
	},
	{
		"...............",
		"....o   .......",
		"......  .......",
		"......⌜⌝.......",
		"......|*...***.",
		"......|x...*y*.",
		"......Y^...***.",
		"......x ....v..",
		"..x***    -CR*.",
		".*⌜---  @ ====.",
		".. x*x    -*rc.",
		".......|=|.....",
		".......*=*.....",
		".......R=r.....",
		"...............",
	},
	{
		"................",
		"......     ****.",
		"..   |     ****.",
		"..r...     ****.",
		"..|...=====    .",
		"..  Yy |R |    .",
		"..     =====^==.",
		".r     R=      .",
		".. ⌜|⌝ == **** .",
		"..x|*|x.. **** .",
		".. ⌞|⌟*.. **** .",
		"..ox=**.. **** .",
		"..@ =....   y  .",
		"..===...........",
		"................",
	},
	{
		"................",
		"..⌜x*x⌝......r..",
		"..x⌜.⌜x...   **.",
		".ox***x r ⌞||**.",
		"..x⌟.⌟x..R-RR...",
		"..⌞x*x⌟..x⌜-x...",
		"........ *x* ...",
		"........ = =v...",
		"........ =@=v...",
		"........ === ...",
		"........     ...",
		"................",
	},
	{
		"...............",
		".....*.........",
		"...x*⌟*x.......",
		"...*===*.⌜⌝....",
		".*.*=*=*.||....",
		".R.s<R<G.|*-Y*.",
		".-..= =..-...^.",
		". .. ⌟ .. ...^.",
		".@       o S  .",
		". ===|=-..|....",
		". | gY= ..x....",
		". =====y..x....",
		". -R*=**.. ....",
		". ====**..*....",
		". -r*=**R *....",
		"...............",
	},
	{
		"................",
		".      @       .",
		".*=*=*=*=*=*=*=.",
		".*=*=*=*=*=*=*=.",
		".*=*=s=*=x=*=x=.",
		".x=*=*=*=*=*=x=.",
		".*=*=*=-=x=*=*=.",
		".*=r=*x*=g=*=S=.",
		".*=*=*=*=*x|x*=.",
		".x=*x⌜=x=*=*=*=.",
		".*x*=*=x=*=*=*=.",
		".*=G=*=*=*=R=*=.",
		".*=*=*=*=*=*=*=.",
		".o=*=*x*=*=⌞ *=.",
		"................",
	},
	{
		"...............",
		".......... @ ..",
		"..........*-x..",
		"..........x-*..",
		".......... ⌞⌟*.",
		"..         .|..",
		".  =====  --⌟..",
		".  =R r=====...",
		".  =    ****...",
		".  =x-⌝........",
		".  = ||........",
		".o xx⌟⌟*rR.....",
		".  --⌝|........",
		".....⌞⌟........",
		"...............",
	},
	{
		"................",
		"....*  x y x  *.",
		".... ......... .",
		".... ...***... .",
		".... >xY***yx< .",
		".x  Y...***...Y.",
		".*== ......... .",
		".x  ⌜*** o ***⌝.",
		".... ===   === .",
		"....x**x @ x**x.",
		"........   .....",
		"................",
	},
	{
		"................",
		".......   x*x  .",
		".......   . .  .",
		".......  ⌞*-*⌟ .",
		".==      ..o.. .",
		".=*⌜x ..x..... .",
		".=R|x ..*..... .",
		".=*⌞x ..x*x*x  .",
		".==@  ..*⌝*..  .",
		".=*⌞x x*x*x..  .",
		".=r-x ....*..  .",
		".=*⌟x ....x..  .",
		".==            .",
		"................",
	},
	{
		"...............",
		".............o.",
		".......** ... .",
		".......v.y...|.",
		".R.....v.⌝⌜ * .",
		".S=*=⌜ @  ⌟..x.",
		".*=r=*..  ...x.",
		".|=|= ..  ...s.",
		".      Yx     .",
		".      ====== .",
		"..... xx****  .",
		"...............",
	},
}

egg_levels := [?][]string {
}
// ⌝⌞⌜⌟
