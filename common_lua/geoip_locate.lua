-- file name: resty/geoip_locate.lua

local _M = {} 		-- �ֲ��ı���
_M._VERSION = '1.0' -- ģ��汾

--���������ժ��LocationDef.h
---------------------------------------------------------------------
local ContinentsCode = {
	"AS",	"EU",	"AF",	"OA",	"NA",	"SA",	"AN"
};
local ContinentsName = {
	"Asia",	"Europe","Africa","Oceania","America","America","Antarctica"
};
---------------------------------------------------------------------
--����
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
--  ���й���   ����ۡ�     ��̨�塱    �����š�   ��������   ���¼��¡�     ��Խ�ϡ�
    "China", "Hongkong", "TaiWan", "Aomen", "Korea", "Singapore", "Vietnam",
-- ��ӡ�������ǡ�  ����ɫ�С�  �����֡�     ��Լ����    �����ʡ�  �������ˡ���Ҳ�š�
    "Indonesia", "Israel", "Bahrein", "Jordan", "Iran", "Iraq", "Yemen",
--  �������ǡ�  �����ȱ��˹̹����������   ��������˹̹��    ��̩����      ��������˹̹��  ��˹��������
    "Syria", "Uzbekistan", "Brunei", "Turkmenistan", "Thailand", "Tajikistan", "Lanka",
--   ��ʥ������          ��ɳ�ء�   ���ձ���   �����͡�   ���Ჴ���� ���ϼ�������    ���ɹš�
    "ChristmasIsland", "Saudi", "Japan", "Palau", "Nepal", "Bangladesh", "Mongolia",
--  ���������ǡ�  ���������  ������ۡ�   �����Ρ�  �������ء�  ���������� ������կ��
    "Malaysia", "Maldives", "Lebanon", "Laos", "Kuwait", "Qatar", "Kampuchea",
--  ��������˹̹��  �����ɱ���       �������뵺��    �������뵺��    �������ʡ�      ��������    ���ͻ�˹̹��
    "Kazakhstan", "Philippines", "TimorLeste", "TimorLeste", "NorthKorea", "Bhutan", "Pakistan",
--  �������ݽ���    ��������  ��������������������    ����������       "ӡ��"   ����顱
    "Azerbaijan", "Oman", "UnitedArabEmirates", "Afghanistan", "India", "Myanmar"
};
--ŷ��
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
--  ������˹��  ���������� ����ʿ��         ��Ӣ����     ���¹���     ��������    ������
    "Russia", "Spain", "Switzerland", "Britain", "Germany", "France", "Denmark",
--  ��������     ��Ų����    ������ʱ��   ����䡱    ��������         ����������  ���������ǡ�
    "Finland", "Norway", "Belgium", "Sweden", "Netherlands", "Curaao", "Armenia",
--  ���������ǡ�  ��ֱ�����ӡ�   ����������  ��Ӣ����     ��������� ����������   ��ϣ����
    "Bulgaria", "Gibraltar", "Jersey", "Britain", "Italy", "Hungary", "Greece",
--  ���ڿ�����   �������䡱  ��˹�߰͵�Ⱥ������ͼ��¬����������Ⱥ����      ��˹�������ǡ� ��˹�工�ˡ�
    "Ukraine", "Turkey", "Svalbard", "Tuvalu", "SolomonIslands", "Slovenia", "Slovakia",
--  ��ʥ����ŵ��   ������·˹������˹����    ���ݿ˹��͹���     ����������    ��ŷ�ˡ�           ��Ħ�ɸ硱
    "SanMarino", "Cyprus", "Yugoslavia", "CzechRepublic", "Portugal", "EuropeanUnion", "Monaco",
--  ���ܿ��������ǡ�������������� ��������� ���������     ���������ǡ� ��¬ɭ����      ����֧��ʿ�ǡ�
    "Micronesia", "Macedonia", "Malta", "IsleOfMan", "Romania", "Luxembourg", "Liechtenstein",
--  ��������     ������ά�ǡ������޵��ǡ� ���ݿ˹��͹���     ������������˹Ⱥ����    ����������     �����������
    "Lithuania", "Latvia", "Croatia", "CzechRepublic", "NetherlandAntilles", "Greenland", "Guernsey",
--  ����ٸԡ�   ������Ⱥ����      ����˹���Ǻͺ�����ά�ǡ�  ��������    ��������     ���׶���˹�� ������˹̹��
    "Vatican", "FaroeIslands", "BosniaAndHerzegovina", "Poland", "Iceland", "Belarus", "Palestine",
--  ������Ⱥ����    ���µ�����   ����������   ����ɳ���ǡ� ����������   �����������ǡ�������ά�ǡ�
    "Ahvenanmaa", "Austria", "Andorra", "Estonia", "Ireland", "Albania",  "Serbia",
--  ��Ħ�����ߡ�
    "Moldova"
};
--����
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
--  ��������     ��������硱    ��ά����(��)��     ������ά�ǡ� �����ô�  ��������   ������ӡ�
    "America", "PuertoRico", "VirginIslands", "Bolivia", "Canada", "Chile", "Jamaica",
--  �������硱   ��ί��������   ��ά����(Ӣ)��     ��Σ��������   ���������Ͷ�͸硱   ���ؿ�˹�Ϳ���˹Ⱥ����     �������ϡ�
    "Uruguay", "Venezuela", "VirginIslands", "Guatemala", "TrinidadAndTobago", "TurksAndCaicosIslands", "Surinam",
--  ��ʥ��ɭ�ص���    ��ʥƤ�������ܿ�¡Ⱥ�� ��   ��ʥ¬���ǵ���  ��ʥ��˹����ά˹��      �������߶ࡱ  ����³���ǡ� ��Ƥ�ؿ�������
    "SaintVincent", "SaintPierreAndMiquelon", "SaintLucia", "SaintKittsAndNevis", "Salvador", "Georgia", "PitcairnIsland",
--  ��������ϡ�   �����������ݺ��Ϸ����뵺��         ��ī���硱  ����³��  �����������ؿ˵���    ��������������ĵ���        ��������Ħ��Ⱥ����
    "Nicaragua", "SouthGeorgiaAndTheSouthIsland", "Mexico", "Peru", "MontserratIsland", "USMinorOutlyingIslands", "AmericanSamoa",
--  ��������˵���  ���ɿ�˹Ⱥ����     ������Ⱥ����       ���鶼��˹��  �����ء�   �������ǡ�  ���ص���
    "Martinique", " CocosIslands", "CaymanIslands", "Honduras", "Hayti", "Guyana", "Guam",
--  ���ϵ����ա�    ���Ű͡�  �������ɴ ����˹����ӡ� �����ױ��ǡ�  ���������� ���չ���
    "Guadeloupe", "Cuba", "Grenada", "CostaRica", "Colombia", "Zaire", "Congo",
--  �����ά��˹Ⱥ���� ������������ ��   ����϶���� ��������ӹ��͹���     ��������ӡ�  ������������Ⱥ����  ����Ľ��
    "MalvieIslands", "FrenchGuiana", "Ecuador", "DominicanRepublic", "Dominica", "MarianaIslands", "Bermuda",
--  ��������    ��������  �������硱    ���͹���   ���ͰͶ�˹��  ������ϺͰͲ��  ����������
    "Brazil", "Panama", "Paraguay", "Bahamas", "Barbados", "AntiguaBarbuda", "Anguilla",
--  ����ɭ�ɵ���          ����¬�͡� ������͢��
    "AscensionIslands", "Aruba", "Argentina"
};
--����
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
--  ���Ϸǹ��͹���   ���������ɡ�  �����ն��� �����   ��Īɣ�ȿˡ�    �����������ǡ������ɡ�
    "SouthAfrica", "Botswana", "Niger", "Gabon", "Mozambique", "Algeria", "Ghana",
--  ��ͻ��˹��   ��Ħ��硱   ��������   �������ǡ� ������¡��    �����ڼӶ��� ��˹��ʿ����
    "Tunisia", "Morocco", "Egypt", "Kenya", "Cameroon", "Senegal", "Swaziland",
--  ����Ͳ�Τ��  �����ױ��ǡ� ���������ǡ� ���յ���   ���ޱ��ǡ�  ��̹ɣ���ǡ�  ��ë����˹��
    "Zimbabwe", "Namibia", "Nigeria", "Sudan", "Zambia", "Tanzania", "Mauritius",
--  ������˹�ӡ�  �����  ����������  �������С�   ������ά��  �������ɷ�����    ���Ա��ǡ�
    "Madagascar", "Mali", "Angola", "Lesotho", "Malawi", "BurkinaFaso", "Gambia",
--  ���ڸɴ  �������ǡ� ��ë�������ǡ�  ���зǹ��͹���              ������������       �������  ��ʥ�����á�
    "Uganda", "Libya", "Mauritania", "CentralAfricanRepublic", "WesternSahara", "Somali", "SaintHelena",
--  ��ʥ�������������ȡ� ���������      ������������     ����Լ�ء�   ��¬���  ������������ ���������ǡ�
    "SaoTomePrincipe", "Seychelles", "SierraLeone", "Mayotte", "Rwanda", "Reunion", "Liberia",
--  ������Ⱥ����       ����Ħ�ޡ�   �������Ǳ��ܡ�    �������ǡ�  ��������˹̹��  �������ᡱ    ����ýǹ��͹���
    "CaymanIslands", "Comoros", "GuineaBissau", "Guinea", "Kyrgyzstan", "Djibouti", "CapeVerde",
--  �����������ǡ�����硱 ����������ǡ�        ����ά����        ����¡�ϡ�   ��Ӣ��ӡ������ء�               ��������
    "Eritrea", "Togo", "EquatorialGuinea", "BouvetIsland", "Burundi", "BritishIndianOceanTerritory", "Benin",
--  ����������ǡ�
    "Ethiopia"
};
--������
local Oceania_CountrysCode = {
    "AU", "NZ", "NC", "VU", "WF", "TK", "TO",
    "WS", "NF", "NU", "NR", "MH", "CK", "KI",
    "HM", "FJ", "TF", "PF", "PG"
};
local Oceania_CountrysName = {
--  ���Ĵ����ǡ�   ����������      ���¿�������ǡ�  ����Ŭ��ͼ�� ������˹�͸�ͼ�ɡ�  ���п���Ⱥ���������ӡ�
    "Australia", "NewZealand", "NewCaledonia", "Vanuatu", "WallisEtFutuna", "Tokelau", "Tonga",
--  ����Ħ�ǡ�                   ��ŵ���˵���       ��Ŧ���������³��   �����ܶ�Ⱥ����       �����Ⱥ�����������˹���͹���
    "IndependentStateOfSamoa", "NorfolkIsland", "Niue", "Nauru", "MarshallIslands", "CookIs", "Kiribati",
--  ���յµ���������ɵ���           ��쳼á�  �������ϲ�������               ���������������ǡ�   ���Ͳ����¼����ǡ�
    "HeardIslandsMcDonaldIslands", "Fiji", "FrenchSouthernTerritories", "FrenchPolynesia", "PapuaNewCuinea"
};
--�ϼ���[û�й���]
--[[
local Antarctica_CountrysCode = {
};
local Antarctica_CountrysName[Antarctica_CountryNum] = {
};
]]
--���й���½����ϸ��
local ChinaProvincesCode = {
    "22", "28", "33", "10", "24", "20", "08",
    "19", "05", "23", "25", "04", "01", "02",
    "03", "07", "12", "11", "30", "31", "16",
    "09", "32", "18", "29", "14", "26", "21",
    "15", "06", "13"
};
local ChinaProvincesName = {
--  ��������     �����     �����족       ���ӱ���   ��ɽ����    �����ɹš�     ����������
    "BeiJing", "TianJin", "ChongQing", "HeBei", "ShanXi", "NeiNengGu", "HeiLongJiang",
--  ��������      �����֡�   ���Ϻ���      ��ɽ����      �����ա�     �����ա�   ���㽭��
    "LiaoNing", "JiLin", "ShangHai", "ShanDong", "JiangSu", "AnHui", "ZheJiang",
--  ��������     ��������    ��������   �����ϡ�   ���㶫��       �����ϡ�    ��������
    "JiangXi", "FuJian", "HuBei", "HuNan", "GuangDong", "HaiNan", "GuangXi",
--  "���ϡ�   ���Ĵ���     �����ݡ�     �����ϡ�    �����ء�    ��������     �����ġ�
    "HeNan", "SiChuan", "GuiZhou", "YunNan", "XiZang", "ShanXi2", "NingXia",
--  �����ࡱ   ���ຣ��     ���½���
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

--��ȡ������Ϣ
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
