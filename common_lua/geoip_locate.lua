-- file name: resty/geoip_locate.lua

local _M = {} 		-- 局部的变量
_M._VERSION = '1.0' -- 模块版本

--下面的内容摘自LocationDef.h
---------------------------------------------------------------------
local ContinentsCode = {
	"AS",	"EU",	"AF",	"OA",	"NA",	"SA",	"AN"
};
local ContinentsName = {
	"Asia",	"Europe","Africa","Oceania","America","America","Antarctica"
};
---------------------------------------------------------------------
--亚洲
local Asia_CountrysCode = {
    "CN", "HK", "TW", "MO", "KR","SG", "VN",
    "ID", "IL", "BH", "JO", "IR", "IQ", "YE",
    "SY", "UZ", "BN", "TM", "TH", "TJ", "LK",
    "CX", "SA", "JP", "PW", "NP", "BD", "MN",
    "MY", "MV", "LB", "LA", "KW", "QA", "KH",
    "KZ", "PH", "TL", "TP", "KP", "BT", "PK",
    "AZ", "OM", "AE", "AF", "IN", "MM"
};
local Asia_CountrysName = {
--  “中国”   “香港”     “台湾”    “澳门”   “韩国”   “新加坡”     “越南”
    "China", "Hongkong", "TaiWan", "Aomen", "Korea", "Singapore", "Vietnam",
-- “印度尼西亚”  “以色列”  “巴林”     “约旦”    “伊朗”  “伊拉克”“也门”
    "Indonesia", "Israel", "Bahrein", "Jordan", "Iran", "Iraq", "Yemen",
--  “叙利亚”  “乌兹别克斯坦”“文莱”   “土库曼斯坦”    “泰国”      “塔吉克斯坦”  “斯里兰卡”
    "Syria", "Uzbekistan", "Brunei", "Turkmenistan", "Thailand", "Tajikistan", "Lanka",
--   “圣诞岛”          “沙特”   “日本”   “帕劳”   “尼泊尔” “孟加拉国”    “蒙古”
    "ChristmasIsland", "Saudi", "Japan", "Palau", "Nepal", "Bangladesh", "Mongolia",
--  “马来西亚”  “马尔代夫”  “黎巴嫩”   “老挝”  “科威特”  “卡塔尔” “柬埔寨”
    "Malaysia", "Maldives", "Lebanon", "Laos", "Kuwait", "Qatar", "Kampuchea",
--  “哈萨克斯坦”  “菲律宾”       “东帝汶岛”    “东帝汶岛”    “北朝鲜”      “不丹”    “巴基斯坦”
    "Kazakhstan", "Philippines", "TimorLeste", "TimorLeste", "NorthKorea", "Bhutan", "Pakistan",
--  “阿塞拜疆”    “阿曼”  “阿拉伯联合酋长国”    “阿富汗”       "印度"   “缅甸”
    "Azerbaijan", "Oman", "UnitedArabEmirates", "Afghanistan", "India", "Myanmar"
};
--欧洲
local Europe_CountrysCode = {
    "RU", "ES", "CH", "GB", "DE", "FR", "DK",
    "FI", "NO", "BE", "SE", "NL", "CW", "AM",
    "BG", "GI", "JE", "UK", "IT", "HU", "GR",
    "UA", "TR", "SJ", "TV", "SB", "SI", "SK",
    "SM", "CY", "YU", "CS", "PT", "EU", "MC",
    "FM", "MK", "MT", "IM", "RO", "LU", "LI",
    "LT", "LV", "HR", "CZ", "AN", "GL", "GG",
    "VA", "FO", "BA", "PL", "IS", "BY", "PS",
    "AX", "AT", "AD", "EE", "IE", "AL", "RS",
    "MD"
};
local Europe_CountrysName = {
--  “俄罗斯”  “西班牙” “瑞士”         “英国”     “德国”     “法国”    “丹麦”
    "Russia", "Spain", "Switzerland", "Britain", "Germany", "France", "Denmark",
--  “芬兰”     “挪威”    “比利时”   “瑞典”    “荷兰”         “库拉索”  “亚美尼亚”
    "Finland", "Norway", "Belgium", "Sweden", "Netherlands", "Curaao", "Armenia",
--  “保加利亚”  “直布罗陀”   “泽西岛”  “英国”     “意大利” “匈牙利”   “希腊”
    "Bulgaria", "Gibraltar", "Jersey", "Britain", "Italy", "Hungary", "Greece",
--  “乌克兰”   “土耳其”  “斯瓦巴德群岛”“图瓦卢”“所罗门群岛”      “斯洛文尼亚” “斯洛伐克”
    "Ukraine", "Turkey", "Svalbard", "Tuvalu", "SolomonIslands", "Slovenia", "Slovakia",
--  “圣马力诺”   “塞浦路斯”“南斯拉夫”    “捷克共和国”     “葡萄牙”    “欧盟”           “摩纳哥”
    "SanMarino", "Cyprus", "Yugoslavia", "CzechRepublic", "Portugal", "EuropeanUnion", "Monaco",
--  “密克罗尼西亚”“马其顿王国” “马耳他” “马恩岛”     “罗马尼亚” “卢森堡”      “列支敦士登”
    "Micronesia", "Macedonia", "Malta", "IsleOfMan", "Romania", "Luxembourg", "Liechtenstein",
--  “立陶宛”     “拉脱维亚”“克罗地亚” “捷克共和国”     “荷兰安的列斯群岛”    “格陵兰”     “格恩西岛”
    "Lithuania", "Latvia", "Croatia", "CzechRepublic", "NetherlandAntilles", "Greenland", "Guernsey",
--  “梵蒂冈”   “法罗群岛”      “波斯尼亚和黑塞哥维那”  “波兰”    “冰岛”     “白俄罗斯” “巴勒斯坦”
    "Vatican", "FaroeIslands", "BosniaAndHerzegovina", "Poland", "Iceland", "Belarus", "Palestine",
--  “奥兰群岛”    “奥地利”   “安道尔”   “爱沙尼亚” “爱尔兰”   “阿尔巴尼亚”“塞尔维亚”
    "Ahvenanmaa", "Austria", "Andorra", "Estonia", "Ireland", "Albania",  "Serbia",
--  “摩尔多瓦”
    "Moldova"
};
--美洲
local America_CountrysCode = {
    "US", "PR", "VI", "BO", "CA", "CL", "JM",
    "UY", "VE", "VG", "GT", "TT", "TC", "SR",
    "VC", "PM", "LC", "KN", "SV", "GE", "PN",
    "NI", "GS", "MX", "PE", "MS", "UM", "AS",
    "MQ", "CC", "KY", "HN", "HT", "GY", "GU",
    "GP", "CU", "GD", "CR", "CO", "CD", "CG",
    "FK", "GF", "EC", "DO", "DM", "MP", "BM",
    "BR", "PA", "PY", "BS", "BB", "AG", "AI",
    "AC", "AW", "AR"
};
local America_CountrysName = {
--  “美国”     “波多黎哥”    “维京岛(美)”     “玻利维亚” “加拿大”  “智利”   “牙买加”
    "America", "PuertoRico", "VirginIslands", "Bolivia", "Canada", "Chile", "Jamaica",
--  “乌拉圭”   “委内瑞拉”   “维京岛(英)”     “危地马拉”   “特立尼达和多巴哥”   “特克斯和凯科斯群岛”     “苏里南”
    "Uruguay", "Venezuela", "VirginIslands", "Guatemala", "TrinidadAndTobago", "TurksAndCaicosIslands", "Surinam",
--  “圣文森特岛”    “圣皮艾尔和密克隆群岛 ”   “圣卢西亚岛”  “圣吉斯和尼维斯”      “萨尔瓦多”  “格鲁吉亚” “皮特凯恩岛”
    "SaintVincent", "SaintPierreAndMiquelon", "SaintLucia", "SaintKittsAndNevis", "Salvador", "Georgia", "PitcairnIsland",
--  “尼加拉瓜”   “南乔治亚州和南方插入岛”         “墨西哥”  “秘鲁”  “蒙特塞拉特克岛”    “美国辅修在外的岛”        “美属萨摩亚群岛”
    "Nicaragua", "SouthGeorgiaAndTheSouthIsland", "Mexico", "Peru", "MontserratIsland", "USMinorOutlyingIslands", "AmericanSamoa",
--  “马提尼克岛”  “可可斯群岛”     “开曼群岛”       “洪都拉斯”  “海地”   “圭亚那”  “关岛”
    "Martinique", " CocosIslands", "CaymanIslands", "Honduras", "Hayti", "Guyana", "Guam",
--  “瓜德罗普”    “古巴”  “格林纳达” “哥斯达黎加” “哥伦比亚”  “扎伊尔” “刚果”
    "Guadeloupe", "Cuba", "Grenada", "CostaRica", "Colombia", "Zaire", "Congo",
--  “马尔维那斯群岛” “法属圭亚那 ”   “厄瓜多尔” “多米尼加共和国”     “多米尼加”  “南马利亚那群岛”  “百慕大”
    "MalvieIslands", "FrenchGuiana", "Ecuador", "DominicanRepublic", "Dominica", "MarianaIslands", "Bermuda",
--  “巴西”    “巴拿马”  “巴拉圭”    “巴哈马”   “巴巴多斯”  “安提瓜和巴布达”  “安奎拉”
    "Brazil", "Panama", "Paraguay", "Bahamas", "Barbados", "AntiguaBarbuda", "Anguilla",
--  “亚森松岛”          “阿卢巴” “阿根廷”
    "AscensionIslands", "Aruba", "Argentina"
};
--非洲
local Africa_CountrysCode = {
    "ZA", "BW", "NE", "GA", "MZ", "DZ", "GH",
    "TN", "MA", "EG", "KE", "CM", "SN", "SZ",
    "ZW", "NA", "NG", "SD", "ZM", "TZ", "MU",
    "MG", "ML", "AO", "LS", "MW", "BF", "GM",
    "UG", "LY", "MR", "CF", "EH", "SO", "SH",
    "ST", "SC", "SL", "YT", "RW", "RE", "LR",
    "CI", "KM", "GW", "GN", "KG", "DJ", "CV",
    "ER", "TG", "GQ", "BV", "BI", "IO", "BJ",
    "ET"
};
local Africa_CountrysName = {
--  “南非共和国”   “博茨瓦纳”  “尼日尔” “加蓬”   “莫桑比克”    “阿尔及利亚”“加纳”
    "SouthAfrica", "Botswana", "Niger", "Gabon", "Mozambique", "Algeria", "Ghana",
--  “突尼斯”   “摩洛哥”   “埃及”   “肯尼亚” “喀麦隆”    “塞内加尔” “斯威士兰”
    "Tunisia", "Morocco", "Egypt", "Kenya", "Cameroon", "Senegal", "Swaziland",
--  “津巴布韦”  “纳米比亚” “尼日利亚” “苏丹”   “赞比亚”  “坦桑尼亚”  “毛里求斯”
    "Zimbabwe", "Namibia", "Nigeria", "Sudan", "Zambia", "Tanzania", "Mauritius",
--  “马达加斯加”  “马里”  “安哥拉”  “莱索托”   “马拉维”  “布基纳法索”    “冈比亚”
    "Madagascar", "Mali", "Angola", "Lesotho", "Malawi", "BurkinaFaso", "Gambia",
--  “乌干达”  “利比亚” “毛里塔尼亚”  “中非共和国”              “西撒哈拉”       “索马里”  “圣赫勒拿”
    "Uganda", "Libya", "Mauritania", "CentralAfricanRepublic", "WesternSahara", "Somali", "SaintHelena",
--  “圣多美和普林西比” “塞舌尔”      “塞拉利昂”     “马约特”   “卢旺达”  “留尼汪岛” “利比里亚”
    "SaoTomePrincipe", "Seychelles", "SierraLeone", "Mayotte", "Rwanda", "Reunion", "Liberia",
--  “开曼群岛”       “科摩罗”   “几内亚比绍”    “几内亚”  “吉尔吉斯坦”  “吉布提”    “佛得角共和国”
    "CaymanIslands", "Comoros", "GuineaBissau", "Guinea", "Kyrgyzstan", "Djibouti", "CapeVerde",
--  “厄立特利亚”“多哥” “赤道几内亚”        “布维岛”        “布隆迪”   “英属印度洋领地”               “贝宁”
    "Eritrea", "Togo", "EquatorialGuinea", "BouvetIsland", "Burundi", "BritishIndianOceanTerritory", "Benin",
--  “埃塞俄比亚”
    "Ethiopia"
};
--大洋洲
local Oceania_CountrysCode = {
    "AU", "NZ", "NC", "VU", "WF", "TK", "TO",
    "WS", "NF", "NU", "NR", "MH", "CK", "KI",
    "HM", "FJ", "TF", "PF", "PG"
};
local Oceania_CountrysName = {
--  “澳大利亚”   “新西兰”      “新喀里多尼亚”  “瓦努阿图” “瓦利斯和富图纳”  “托克劳群岛”“汤加”
    "Australia", "NewZealand", "NewCaledonia", "Vanuatu", "WallisEtFutuna", "Tokelau", "Tonga",
--  “萨摩亚”                   “诺福克岛”       “纽埃岛”“瑙鲁”   “马绍尔群岛”       “库克群岛”“基里巴斯共和国”
    "IndependentStateOfSamoa", "NorfolkIsland", "Niue", "Nauru", "MarshallIslands", "CookIs", "Kiribati",
--  “赫德岛和麦克唐纳岛”           “斐济”  “法属南部领土”               “法属玻利尼西亚”   “巴布亚新几内亚”
    "HeardIslandsMcDonaldIslands", "Fiji", "FrenchSouthernTerritories", "FrenchPolynesia", "PapuaNewCuinea"
};
--南极洲[没有国家]
--[[
local Antarctica_CountrysCode = {
};
local Antarctica_CountrysName[Antarctica_CountryNum] = {
};
]]
--对中国大陆地区细化
local ChinaProvincesCode = {
    "22", "28", "33", "10", "24", "20", "08",
    "19", "05", "23", "25", "04", "01", "02",
    "03", "07", "12", "11", "30", "31", "16",
    "09", "32", "18", "29", "14", "26", "21",
    "15", "06", "13"
};
local ChinaProvincesName = {
--  “北京”     “天津”     “重庆”       “河北”   “山西”    “内蒙古”     “黑龙江”
    "BeiJing", "TianJin", "ChongQing", "HeBei", "ShanXi", "NeiNengGu", "HeiLongJiang",
--  “辽宁”      “吉林”   “上海”      “山东”      “江苏”     “安徽”   “浙江”
    "LiaoNing", "JiLin", "ShangHai", "ShanDong", "JiangSu", "AnHui", "ZheJiang",
--  “江西”     “福建”    “湖北”   “湖南”   “广东”       “海南”    “广西”
    "JiangXi", "FuJian", "HuBei", "HuNan", "GuangDong", "HaiNan", "GuangXi",
--  "河南”   “四川”     “贵州”     “云南”    “西藏”    “陕西”     “宁夏”
    "HeNan", "SiChuan", "GuiZhou", "YunNan", "XiZang", "ShanXi2", "NingXia",
--  “甘肃”   “青海”     “新疆”
    "GanSu", "QingHai", "XinJiang"
};
---------------------------------------------------------------------
local ContinentsMap	= {}
local Asia_CountrysMap		= {}
local Europe_CountrysMap	= {}
local America_CountrysMap	= {}
local Africa_CountrysMap	= {}
local Oceania_CountrysMap	= {}
local ChinaProvincesMap = {}

for i = 1, #ContinentsCode do
	ContinentsMap[ContinentsCode[i]] = ContinentsName[i]
end
for i = 1, #Asia_CountrysCode do
	Asia_CountrysMap[Asia_CountrysCode[i]] = Asia_CountrysName[i]
end
for i = 1, #Europe_CountrysCode do
	Europe_CountrysMap[Europe_CountrysCode[i]] = Europe_CountrysName[i]
end
for i = 1, #America_CountrysCode do
	America_CountrysMap[America_CountrysCode[i]] = America_CountrysName[i]
end
for i = 1, #Africa_CountrysCode do
	Africa_CountrysMap[Africa_CountrysCode[i]] = Africa_CountrysName[i]
end
for i = 1, #Oceania_CountrysCode do
	Oceania_CountrysMap[Oceania_CountrysCode[i]] = Oceania_CountrysName[i]
end
for i = 1, #ChinaProvincesCode do
	ChinaProvincesMap[ChinaProvincesCode[i]] = ChinaProvincesName[i]
end

--获取区域信息
function _M.get_location_from_geoip ()
	local continent = "Default"
	local country = "Default"
	local city = "Default"
	if (ngx.var.geoip_city_continent_code) and ContinentsMap[ngx.var.geoip_city_continent_code] then
		continent = ContinentsMap[ngx.var.geoip_city_continent_code]
		if(ngx.var.geoip_city_country_code) then
			if ngx.var.geoip_city_continent_code == "AS" and Asia_CountrysMap[ngx.var.geoip_city_country_code] then
				country = Asia_CountrysMap[ngx.var.geoip_city_country_code]
				if ngx.var.geoip_country_code == "CN" and ngx.var.geoip_city then
					city = ngx.var.geoip_city
				end
			elseif ngx.var.geoip_city_continent_code == "EU" and Europe_CountrysMap[ngx.var.geoip_city_country_code] then
				country = Europe_CountrysMap[ngx.var.geoip_city_country_code]
			elseif ngx.var.geoip_city_continent_code == "AF" and Africa_CountrysCode[ngx.var.geoip_city_country_code] then
				country = Africa_CountrysCode[ngx.var.geoip_city_country_code]
			elseif ngx.var.geoip_city_continent_code == "OA" and Oceania_CountrysMap[ngx.var.geoip_city_country_code] then
				country = Oceania_CountrysMap[ngx.var.geoip_city_country_code]
			elseif ngx.var.geoip_city_continent_code == "NA" and Africa_CountrysMap[ngx.var.geoip_city_country_code] then
				country = Africa_CountrysMap[ngx.var.geoip_city_country_code]
			elseif ngx.var.geoip_city_continent_code == "SA" and Africa_CountrysMap[ngx.var.geoip_city_country_code] then
				country = Africa_CountrysMap[ngx.var.geoip_city_country_code]
			end
		end
	end
	return continent..":"..country..":"..city
end
return _M
