package main

Campaign :: enum {
	Carrot_Harvest,
	Easter_Eggs,
}

char_to_tile: map[rune]Tiles = {
	'.' = .Grass,
	' ' = .Ground,
	'@' = .Start,
	'o' = .End,
	'*' = .Carrot,
	'=' = .Fence,
	'x' = .Trap,
	'X' = .Trap_Activated,
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
	'e' = .Egg_Spot,
	'E' = .Egg,
}

carrot_levels := [?][]string {
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
	{
		".......",
		".. @ ..",
		".     .",
		".e=== .",
		".e=== .",
		".eeeee.",
		".eeeee.",
		".eeoee.",
		".eeeee.",
		".......",
	},
	{
		"..........",
		"..   @....",
		"..    ....",
		"..  ......",
		"..⌞⌝......",
		"..⌞⌟......",
		".Ye eeeee.",
		".x  e<e ⌝.",
		"..⌞⌝......",
		"..⌞⌟......",
		"..⌞⌟......",
		".     ....",
		".  o  ....",
		"..........",
	},
	{
		"............",
		"....@   eee.",
		"....  = eXe.",
		"....  = ⌝ e.",
		".... ee |==.",
		".eeeeeee|x..",
		".eeeeeee⌟e..",
		".eeXee......",
		". eeeo......",
		"............",
	},
	{
		"...............",
		".             .",
		".  ⌜⌜⌜   ⌝⌝⌝  .",
		". ⌝|e|⌝ ⌝|e|⌞ .",
		". ⌝|e|⌝ ⌜|e|⌝ .",
		".  ⌜⌜⌜ @ ⌜⌟⌟  .",
		".     R r     .",
		".      o      .",
		".  ⌞⌞   ⌟⌞⌟⌟⌟ .",
		". ⌞--⌞  ⌟---⌝ .",
		". ⌞ee⌞  ⌞eee⌟ .",
		". ⌞--⌞  ⌟---⌞ .",
		".  ⌞⌞   ⌜⌟⌞⌟⌟ .",
		".             .",
		"...............",
	},
	{
		"...............",
		".  R  |⌜⌞|  R .",
		". ee  =ee=  e .",
		". ee  =ee=  e .",
		".     =e =    .",
		".     =  =    .",
		". =====  ====|.",
		".⌝eee  @R  ee|.",
		".⌟eee  ro  ee|.",
		". =====  ====|.",
		".   R =ee= r  .",
		". ee  =ee=  e .",
		". ee  =ee=  e .",
		".     -⌜⌝-    .",
		"...............",
	},
	{
		"..................",
		"..e====.....  ===.",
		".. =ee=.....  ⌝e=.",
		"..  ⌜⌝ ..ee  ⌜⌟e=.",
		".. ⌞⌟  ..e== ⌞ ==.",
		"..       e==    ..",
		"..... ===e==e== ..",
		"..... ===⌝eereeo..",
		"..    eee@==e== ..",
		".== ⌝ ===e==e== ..",
		".=e⌜⌟ ===e=R    ..",
		".=e⌞  =  ⌟  ⌜⌝  ..",
		".==   =e...  ⌞⌟ ..",
		"..     e... =ee=..",
		"............====..",
		"..................",
	},
	{
		"................",
		".ye> Ye   =⌝ee@.",
		".e= ===   = == .",
		".e=            .",
		".⌜             .",
		".e=.. =|=|==== .",
		".v=.. =e=eeRe- .",
		".  .. =r=e==== .",
		".     = =eee⌜- .",
		".==   e⌟eee= = .",
		".⌝    ====e=e= .",
		".e=.. -Reee=e= .",
		".e=.. ====x=|= .",
		".o=..          .",
		"................",
	},
	{
		"...............",
		".            o.",
		". =e========= .",
		". =eyceeeeeRe .",
		". =e=e=====S= .",
		". =e=Yee<Ree= .",
		". =e=eXeXr=e= .",
		". =g=⌞esye=e= .",
		". =e=eXeXe=v= .",
		". =eGee⌝e⌝=e= .",
		". =e=====e=e= .",
		". e⌟eeReeCer= .",
		". =========e= .",
		".@           Y.",
		"...............",
	},
	{
		"...............",
		".            o.",
		". =====e=e=e= .",
		". eeeee⌝=e=e= .",
		". =====c=v=r= .",
		". eeRe<e=e=e= .",
		". =====e=e=e= .",
		". e⌝ese⌝eSe⌝e .",
		". =e=e=e===== .",
		". =e=R=Cee>ee .",
		". =Y=e=e===== .",
		". =e=e=yeeree .",
		". =e=e=e===== .",
		".@            .",
		"...............",
	},
	{
		"................",
		".......e........",
		".......Y........",
		".......R........",
		".......|........",
		"....oS   -rye...",
		"...... @ .......",
		"......    ......",
		".     v==^    =.",
		".      ==   =|=.",
		".=|=|=|==|=|=R=.",
		".=R=R=r==R=r=y=.",
		".=Y=e=e==e=Y=s=.",
		".==========e===.",
		"................",
	},
	{
		"................",
		".             @.",
		".   ==  ==ee== .",
		". =e==e===ye== .",
		". =ReY⌝=ee--ee⌝.",
		". =e== =ee--ee⌜.",
		". =e==e===ee== .",
		". ee>er= =vv== .",
		". ====e===ee== .",
		".   eeeoee--e= .",
		".   ===eee--e= .",
		"... ===e==ee== .",
		"...    ⌞==ee== .",
		"...       ⌝⌟   .",
		"................",
	},
	{
		"................",
		".......       ..",
		"....... ===== ..",
		"....... = @ = ..",
		"....... =eee= ..",
		"....... =eve= ..",
		"....... = e = ..",
		".       = ve=  .",
		".========| |===.",
		".eeeX    ⌟|⌞ s=.",
		".eeee⌝ == c =e=.",
		".eeeee =    =e=.",
		".eeeCX g⌝ o Ge=.",
		".===   eeS=====.",
		"................",
	},
	{
		"...............",
		"..           ..",
		".    . ..     .",
		".  ..yeee..   .",
		".  ..eere..   .",
		". =ee-ee-ee=  .",
		".  eRe..eRe   .",
		". =eee..eYe=  .",
		". =re|ee|ee=  .",
		".  ..e<<e..   .",
		".  ........   .",
		".    ....     .",
		".             .",
		"..   o  @    ..",
		"...............",
	},
	{
		"...............",
		".             .",
		". ==== @ ==== .",
		". =ree   eeR= .",
		". =e=== ===e= .",
		". =e=⌞eee⌜=e= .",
		".   =e⌟|⌝e=   .",
		".   =e⌟-⌜e=   .",
		". =e=⌟ree⌜=e= .",
		". =e=== ===e= .",
		". =Ree   eer= .",
		". ==== o ==== .",
		".             .",
		"...............",
	},
	{
		"................",
		".eeeeeee=======.",
		".eee⌜⌝⌝    ⌝   .",
		".eee⌟⌟⌟   = e= .",
		".====     =e =e.",
		".       === o e.",
		".     === ==== .",
		". ===xee= -Re= .",
		".   =x|e= -R== .",
		". ⌟|=x||=@-re= .",
		". -r= |e= ==== .",
		". ⌞e= ||= |    .",
		". === e^====== .",
		".    <<<eee    .",
		"................",
	},
}
// ⌝⌞⌜⌟

all_levels: [Campaign][][]string = {
	.Carrot_Harvest = carrot_levels[:],
	.Easter_Eggs = egg_levels[:],
}
