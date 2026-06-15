-- Auto-generated from vanilla_wow_classic_grinding_locations_expanded_addon_db.xlsx sheet 'Addon_DB'.
-- Update the workbook, then rerun tools\Convert-GrindLocationsFromXlsx.ps1.
local function SplitList(value)
    local result = {}
    if not value or value == "" then
        return result
    end
    for item in string.gmatch(value, "([^;]+)") do
        table.insert(result, item)
    end
    return result
end

local function SplitFields(line)
    local result = {}
    for value in string.gmatch(line .. "|", "([^|]*)|") do
        table.insert(result, value)
    end
    return result
end

local function FactionName(value)
    if value == "A" then
        return "Alliance"
    elseif value == "H" then
        return "Horde"
    end
    return "Both"
end

local rawData = [=[
vg001|1|6|H|Durotar|Valley of Trials / Sen'jin approaches|Boars;Scorpids;Trolls|1-6|3|2|1|2|2|3|49
vg002|1|6|H|Tirisfal Glades|Deathknell and Solliden Farmstead|Young Night Web Spiders;Duskbats;Zombies;Scarlet Converts|1-6|3|2|1|2|3|3|49
vg003|1|6|H|Mulgore|Camp Narache / Red Cloud Mesa|Plainstriders;Wolves;Bristlebacks|1-6|3|2|1|2|3|3|48
vg004|1|6|A|Teldrassil|Shadowglen and Aldrassil outskirts|Grell;Nightsabers;Webwood Spiders|1-6|3|2|1|2|3|3|47
vg005|1|6|A|Elwynn Forest|Northshire / first camps|Kobolds;Wolves;Defias Cutpurses|1-5|3|2|1|2|2|4|46
vg006|5|10|H|Tirisfal Glades|Agamand Mills / Brill outskirts|Rattlecage Skeletons;Rot Hide Gnolls;Scarlet Warriors|5-10|3|3|1|3|4|3|55
vg007|5|10|A|Dun Morogh|Coldridge / Frostmane camps|Frostmane Trolls;Wolves;Boars|5-10|3|3|1|2|2|5|45
vg008|6|10|H|Durotar|Echo Isles shoreline and Sen'jin coast|Darkspear Trolls;Makrura;Pygmy Surf Crawlers|6-10|3|2|1|3|2|4|65
vg009|6|10|H|Mulgore|Bristleback Ravine / Palemane Rock|Bristleback Quilboar;Palemane Gnolls;Prairie Wolves|6-10|3|5|1|3|4|3|58
vg010|6|10|A|Teldrassil|Starbreeze Village / Ban'ethil Barrow Den surface|Timberlings;Gnarlpine Furbolgs;Strigid Owls|6-10|3|3|1|3|4|3|55
vg011|7|10|H|Tirisfal Glades|Scarlet Outpost / north of Brill|Scarlet Warriors;Scarlet Missionaries|7-10|3|2|1|3|4|3|66
vg012|7|10|A|Elwynn Forest|Fargodeep Mine / farms|Kobolds;Boars|7-10|4|4|1|5|3|4|92
vg013|8|11|A|Elwynn Forest|Rolf's corpse / Eastvale murlocs|Murlocs|9-11|4|2|1|4|2|3|79
vg014|8|12|A|Darkshore|Auberdine south and north road wildlife|Moonstalker Runts;Rabid Thistle Bears;Foreststriders|8-12|3|2|1|3|3|3|58
vg015|9|13|A|Loch Modan|Thelsamar lakeside / Silver Stream Mine edges|Kobolds;Boars;Bears;Spiders|9-13|3|2|1|3|3|3|58
vg016|10|14|H|The Barrens|North of Crossroads / Stagnant Oasis edge|Zhevra;Plainstriders;Savannah Huntresses|10-14|4|2|1|3|3|4|64
vg017|10|16|A|Westfall|Northwest coast|Crabs / Crawlers|13-14|4|2|1|5|3|3|96
vg018|10|13|A|Elwynn Forest|Farms near Goldshire / Stonefield-Maclure area|Boars|9-12|4|2|1|5|2|5|92
vg019|11|14|H|The Barrens|Circle around Crossroads|Lions;Plainstriders;wildlife|11-14|4|2|2|4|3|3|73
vg020|11|15|H|The Barrens|Thorn Hill and surrounding quilboar camps|Razormane Quilboar|12-15|4|2|2|4|3|3|73
vg021|12|16|H|The Barrens|The Forgotten Pools / Lushwater Oasis loops|Oasis Snapjaws;Kolkar;Plainstriders|12-16|3|3|2|3|3|3|62
vg022|13|17|H|The Barrens|Northwatch Hold exterior|Theramore Marines;Guards;Cannoneers|14-17|4|5|2|4|4|3|75
vg023|14|18|H|The Barrens|Dry Hills|Witchwing Harpies|14-18|4|2|2|4|3|3|76
vg024|14|15|H|The Barrens|South-west of Sludge Fen|Savannah Lions|14-15|4|2|2|4|2|3|73
vg025|14|17|A|Westfall|Defias coast camps / western shed near Defias cave|Defias Looters / Defias humanoids|13-17|4|3|2|5|4|3|95
vg026|15|19|H|The Barrens|Boulder Lode Mine exterior and entry|Venture Co. Peons;Enforcers;Overseers|16-18|4|5|2|4|3|3|75
vg027|16|20|H|Silverpine Forest|Fenris Isle shoreline and keep|Rot Hide Gnolls|16-20|4|3|2|4|4|3|74
vg028|16|22|H|Silverpine Forest|Fenris Isle & Keep|Rot Hide Gnolls|16-22|4|3|2|4|3|3|73
vg029|16|18|H|The Barrens|Boulder Lode Mine|Venture Co. mobs|16-18|4|5|2|4|2|5|73
vg030|17|21|H|Stonetalon Mountains|Windshear Crag|Venture Co. Loggers and Deforesters|17-21|4|3|2|4|4|4|70
vg031|17|19|A|Loch Modan|Crocolisk island south of Ironband's Excavation|Loch Crocolisks|14-17|4|4|2|5|3|3|94
vg032|17|23|A|Westfall|Southwest coast near Lighthouse|Higher-level crabs / crawlers|17-18|4|2|2|5|3|3|94
vg033|17|19|A|Loch Modan|Ironband Excavation Site|Stonesplinter Troggs|17-19|4|3|2|4|2|4|70
vg034|18|22|H|The Barrens|Raptor Grounds / south of Crossroads|Sunscale Raptors|17-22|4|2|2|3|2|3|66
vg035|18|22|B|Redridge Mountains|Lake Everstill shore and murloc camps|Murlocs;Gnolls;Blackrock Orcs|18-22|3|2|2|3|3|3|62
vg036|18|22|A|Darkshore|Mist's Edge and Bashal'Aran loops|Greymist Murlocs;Moonstalkers;Dark Strand cultists|18-22|3|4|2|3|3|3|62
vg037|19|21|H|Silverpine Forest|Beren's Peril|Ravenclaw Undead|19-21|4|2|2|4|4|3|73
vg038|19|23|H|The Barrens|Merchant Coast / Ratchet pirates|Southsea Brigands and Cannoneers|18-22|4|3|2|4|4|4|70
vg039|19|24|A|Duskwood|Raven Hill Cemetery|Skeletal undead|19-24|4|4|2|4|3|3|72
vg040|20|24|H|Hillsbrad Foothills|Hillsbrad Fields|Hillsbrad Farmers and Peasants|22-25|4|3|2|4|4|4|82
vg041|20|24|H|Ashenvale|Foulweald camp south of Raynewood|Foulweald Furbolgs|21-25|4|2|2|4|4|5|74
vg042|21|25|B|Wetlands|Mosshide camps outside Loch Modan tunnel|Mosshide Gnolls|21-24|5|3|3|5|4|4|94
vg043|21|24|B|Wetlands|Near Loch Modan tunnel|Mosshide Gnolls|21-24|4|3|3|5|4|3|93
vg044|21|25|H|The Barrens|Bael'dun Digsite|Bael'dun Dwarves;Surveyors|21-23|4|2|3|4|4|3|76
vg045|21|23|H|The Barrens|Bael'Dun Dig Site|Bael'dun Dwarves|21-23|4|2|3|4|3|3|73
vg046|21|26|A|Redridge Mountains|Shadowhide camps|Shadowhide Gnolls|21-26|4|3|3|4|4|3|70
vg047|22|26|H|Hillsbrad Foothills|Azurelode Mine|Hillsbrad Miners and Sentries|26-28|4|4|3|4|4|3|78
vg048|22|25|H|Hillsbrad Foothills|Hillsbrad Fields|Farmers / Peasants|22-25|4|4|3|4|3|4|73
vg049|22|26|H|Stonetalon Mountains|Windshear Mine interior edge|Venture Co. Miners and Operators|22-26|4|5|3|4|3|3|70
vg050|22|24|A|Duskwood|Southeast Duskwood|Skeleton Mages and Knights|22-24|4|4|3|4|3|3|70
vg051|23|27|H|Thousand Needles|Freewind Post approach / Galak camps|Galak Centaurs|24-28|3|2|3|3|4|3|66
vg052|24|28|B|Thousand Needles|Highperch|Highperch Wyverns|28-31|4|2|3|4|3|3|76
vg053|24|27|B|Wetlands|North-west Wetlands|Red Whelp;Lost Whelp;Crimson Whelp;Flamesnorting Whelp|23-27|3|2|3|4|1|3|76
vg054|24|29|A|Duskwood|Raven Hill Cemetery surface|Skeletal undead|24-29|4|4|3|4|3|3|78
vg055|25|29|H|Stonetalon Mountains|Charred Vale entry and harpy ridge|Bloodfury Harpies;Chimaeras;Basilisks|25-29|3|3|3|3|2|3|64
vg056|25|28|A|Wetlands|Angerfang Encampment|Dragonmaw Orcs|25-28|4|3|3|4|4|3|70
vg057|26|29|B|Wetlands|Archaeological site|Mottled Scytheclaw;Mottled Razormaw|25-27|4|3|3|5|1|4|92
vg058|26|28|H|Hillsbrad Foothills|Azurelode Mine|Hillsbrad Miners / Sentries|26-28|4|4|3|4|3|3|73
vg059|26|30|H|Ashenvale|Satyrnaar and Warsong Lumber Camp edges|Satyrs;Warsong enemies;Furbolgs|26-30|3|3|3|3|5|4|64
vg060|26|28|A|Duskwood|Raven Hill Tomb|Plague Spreaders|26-28|4|4|3|4|3|3|70
vg061|26|30|A|Wetlands|Whelgar's Excavation / raptor loops|Young Wetlands Raptors;Gnolls;Oozes|26-30|3|2|3|3|3|3|63
vg062|27|32|H|Thousand Needles|Windbreak Canyon and harpy caves|Witchwing / Highperch Harpies|28-32|5|5|3|5|3|3|91
vg063|27|31|H|Hillsbrad Foothills|Darrow Hill / Yeti cave|Cave Yetis|30-32|4|5|3|4|3|3|70
vg064|28|34|B|Razorfen Kraul|Boar area after Charlga route|Agam'ar and Raging Agam'ar boars|28-34|5|2|3|4|2|3|80
vg065|28|31|B|Thousand Needles|Highperch|Highperch Wyverns|28-31|4|3|3|4|3|3|73
vg066|28|32|B|Desolace|Kodo Graveyard and central plains|Aged Kodos;Scorpashi;Kolkar centaurs|28-32|3|3|3|3|3|3|62
vg067|29|32|H|Ashenvale|Demon Fall / Splintertree-adjacent infernal area|Searing Infernal|29-32|3|3|3|4|1|3|77
vg068|29|33|H|Thousand Needles|Shimmering Flats raceway outskirts|Basilisks;Turtles;Buzzards;Hyenas|29-35|4|2|3|4|3|3|76
vg069|29|35|B|Thousand Needles|Shimmering Flats|Beasts|29-35|4|2|3|4|3|3|70
vg070|29|33|A|Duskwood|Mistmantle Manor|Ghouls|29-33|4|3|3|4|4|3|70
vg071|30|35|H|Thousand Needles|Harpy cave / first pulls inside and outside|Harpy mobs|30-35|4|3|3|5|4|3|100
vg072|30|34|B|Stranglethorn Vale|Nesingwary camp surrounding plains|Young Panthers;Tigers;Raptors|31-34|4|4|3|4|3|4|74
vg073|30|35|H|Desolace|Magram/Gelkis outer camps|Magram or Gelkis Centaurs|31-35|3|3|3|3|4|3|64
vg074|30|35|B|Alterac Mountains|Lake near Dalaran|Snapjaws|30-35|3|3|3|3|3|4|63
vg075|30|34|A|Arathi Highlands|Go'Shek Farm|Hammerfall Orcs / farm NPCs|33-35|4|2|3|4|4|3|70
vg076|31|35|B|Arathi Highlands|Witherbark Village|Witherbark Trolls|32-36|4|3|3|4|5|3|76
vg077|31|34|B|Alterac Mountains|Sofera's Naze north of Tarren Mill|Syndicate Humans|31-34|4|3|3|4|4|3|73
vg078|31|37|B|Stranglethorn Vale|Nesingwary Expedition surroundings|Tigers;Panthers;Raptors|31-37|4|3|3|4|2|5|73
vg079|31|36|H|Desolace|Mannoroc Coven / Sargeron edges|Burning Blade Satyrs;Hatefury Satyrs|31-36|3|3|3|3|4|3|66
vg080|32|40|B|Scarlet Monastery|Graveyard / Library / Armory transitions|Scarlet humanoids;undead|32-40|5|3|3|4|2|3|78
vg081|32|36|B|Alterac Mountains|Crushridge Hold north-west|Crushridge Ogres|33-36|4|3|3|4|4|3|73
vg082|32|36|B|Stranglethorn Vale|Kurzen Compound lower camps|Kurzen Jungle Fighters;Medicine Men;Commandos|32-36|4|5|3|4|4|5|70
vg083|32|33|B|Stranglethorn Vale|Below Kurzen base|Stranglethorn Tiger|32-33|3|4|3|3|1|4|67
vg084|33|38|B|Arathi Highlands|Ogre cave west of Refuge Pointe|Boulderfist Ogres|33-38|4|5|3|4|5|3|80
vg085|33|38|H|Swamp of Sorrows|Northern road / Lost One camps|Lost One Muckdwellers and Seers|33-38|4|3|3|4|4|3|76
vg086|33|38|A|Arathi Highlands|West of Refuge Pointe / Ogre cave loop|Ogres|33-38|4|4|3|4|4|3|72
vg087|34|39|H|Dustwallow Marsh|Brackenwall-adjacent spider/raptor loops|Darkmist Spiders;Bloodfen Raptors|35-39|4|3|3|4|2|3|78
vg088|34|39|B|Dustwallow Marsh|North of Brackenwall Village|Darkmist Spiders|35-39|4|3|3|4|3|3|75
vg089|34|38|B|Badlands|Lesser Rock Elemental plateau|Lesser Rock Elementals|36-39|3|2|3|3|4|3|66
vg090|35|39|B|Dustwallow Marsh|Witch Hill / Swamplight Manor|Murlocs;Raptors;Crocolisks|35-39|5|2|3|5|2|3|90
vg091|35|38|B|Swamp of Sorrows|Whelp areas north/east of Stonard|Adolescent Whelp;Dreaming Whelp|34-36|3|3|3|4|3|4|76
vg092|35|38|B|Dustwallow Marsh|North of Brackenwall / Darkmist areas|Darkmist Spider;Darkfang Spider|35-38|3|4|3|4|1|3|74
vg093|35|39|B|Dustwallow Marsh|North of Brackenwall Village|Darkmist Spiders|35-39|4|3|3|4|1|3|70
vg094|35|40|B|Stranglethorn Vale|Gurubashi / troll ruins edges|Bloodscalp and Skullsplitter Trolls|35-40|4|5|3|4|4|5|70
vg095|36|40|B|Dustwallow Marsh|Witch Hill / Bloodfen areas|Bloodfen Raptors|36-40|4|2|3|4|3|3|73
vg096|36|40|B|Badlands|Whelpling ridge east / Dustbowl|Scalding Whelps|39-41|3|2|3|4|3|4|72
vg097|37|40|B|Arathi Highlands|Circle of Elements|Cresting Exile;Thundering Exile;Burning Exile|38-39|3|4|3|4|1|5|78
vg098|37|41|B|Badlands|Apocryphan's Rest carcass south of Kargath|Giant Buzzards|39-41|4|2|3|4|3|3|76
vg099|38|45|B|Scarlet Monastery|Cathedral|Scarlet monks;champions;casters|38-45|5|4|3|4|5|3|80
vg100|38|43|H|Badlands|Kargath buzzard/rock elemental loops|Giant Buzzards;Rock Elementals|39-43|4|3|3|4|3|4|78
vg101|38|43|B|Badlands|Lethlor Ravine outskirts|Scalding Whelp|41-43|3|3|3|4|2|4|77
vg102|38|42|B|Dustwallow Marsh|Witch Hill raptor loops|Bloodfen Raptors|36-40|4|2|3|4|2|3|77
vg103|39|43|B|Feralas|Woodpaw Hills and central gnoll camps|Woodpaw Gnolls|39-44|4|2|3|4|4|3|75
vg104|39|41|B|Badlands|Apocryphan's Rest|Giant Buzzards|39-41|4|2|3|4|2|3|70
vg105|40|45|B|Tanaris|Waterspring Field|Wastewander Bandits and Thieves|40-45|4|4|3|4|4|4|78
vg106|40|44|B|Feralas|Grimtotem Compound|Grimtotem Tauren|40-43|4|3|3|4|4|3|75
vg107|40|45|B|Tanaris|Waterspring Field|Wastewander Pirates|40-45|4|4|3|4|3|5|75
vg108|40|43|B|Feralas|Grimtotem Compound|Grimtotem Tauren|40-43|4|3|3|4|4|3|70
vg109|40|46|H|Feralas|Camp Mojache east/south beast loops|Longtooth Runners;Bears;Yetis;Gnolls|40-46|4|2|3|4|3|3|70
vg110|41|45|B|Swamp of Sorrows|Misty Reed Shore|Marsh Murlocs|41-45|4|3|4|4|4|3|76
vg111|41|45|B|Swamp of Sorrows|Misty Reed Shore|Marsh Murlocs|41-45|4|2|4|4|2|4|70
vg112|41|46|B|Stranglethorn Vale|Gorilla island / Mistvale Valley|Elder Mistvale Gorillas;Panthers;Tigers|41-46|4|3|4|3|3|4|68
vg113|42|46|B|Badlands|Southwest Badlands|Greater Rock Elementals|42-46|3|2|4|4|3|4|76
vg114|42|47|B|Tanaris|Dunemaul Compound|Dunemaul Ogres|44-48|4|3|4|4|5|3|73
vg115|42|46|B|Badlands|Agmond's End|Enraged Rock Elementals|42-43|3|3|4|3|4|4|68
vg116|43|48|B|Tanaris|Lost Rigger Cove|Southsea Pirates|43-51|5|4|4|5|4|3|86
vg117|43|49|H|Tanaris|Gadgetzan-to-Lost Rigger corridor|Wastewander Bandits;Dunemaul Ogres;Pirates|43-49|5|3|4|4|4|4|82
vg118|43|51|B|Tanaris|Lost Rigger Cove|Southsea Pirates|43-51|4|3|4|4|4|3|78
vg119|44|52|B|Zul'Farrak|Graveyard area|Zul'Farrak undead and trolls|44-52|5|3|4|4|4|3|82
vg120|44|48|B|Searing Gorge|The Cauldron / Dark Iron camps|Dark Iron Dwarves;Slavers;Taskmasters|44-48|4|4|4|4|5|3|72
vg121|44|48|B|Searing Gorge|Dark Iron areas / Incendosaur cave|Dark Iron Dwarves;Incendosaurs|44-48|4|3|4|4|4|3|70
vg122|44|48|B|Tanaris|Dunemaul Compound|Dunemaul Ogres|44-48|4|2|4|4|4|3|70
vg123|44|49|B|Hinterlands|Jintha'Alor lower terraces|Vilebranch Trolls|45+|4|5|4|3|5|3|69
vg124|45|50|B|Feralas|Northspring harpy ridges|Northspring Harpies|47-50|4|3|4|4|4|3|74
vg125|45|47|B|The Hinterlands|Central zone|Green Sludges|45-47|4|2|4|4|2|3|70
vg126|45|49|B|Hinterlands|Central slime pools|Green Sludges|45-47|3|2|4|3|3|3|67
vg127|46|51|H|Blasted Lands|Nethergarde Mine|Nethergarde Miners and Humans|46-51|4|2|4|4|4|3|76
vg128|46|49|B|Azshara|Ghost fields between Horde/Alliance flight paths|Ghosts|46-48|3|3|4|3|3|4|66
vg129|47|52|H|Feralas|Camp Mojache north / Rage Scar Vale|Rage Scar Yetis and Northspring Harpies|47-52|4|3|4|4|3|3|74
vg130|47|50|B|Feralas|Northspring Harpy area|Northspring Harpies|47-50|4|3|4|4|4|3|70
vg131|47|50|B|Un'Goro Crater|Ravasaur areas|Ravasaur Raptors|47-50|4|3|4|4|3|3|70
vg132|47|52|B|Azshara|Ruins of Eldarath / coastline|Naga;Highborne ghosts;Hippogryphs|47-52|3|2|4|3|5|2|67
vg133|47|54|A|Feralas|Isle south of Feathermoon Stronghold / Naga cave|Nagas|47-54|4|3|4|4|5|4|82
vg134|48|53|B|Blasted Lands|Western/southern beast loops|Basilisks;Scorpids;Vultures;Boars;Snickerfang Hyenas|48-53|4|3|4|4|1|3|80
vg135|48|53|B|Blasted Lands|Beast loops across zone|Basilisks;Scorpids;Vultures;Boars;Snickerfangs|45-53|3|3|4|4|1|3|77
vg136|48|55|H|Felwood|Bloodvenom Post access loops|Deadwood Furbolgs;wolves;bears;Warpwood elementals|48-55|4|4|4|4|4|3|76
vg137|48|52|B|Feralas|Western coastline pools and elite-giant zap quests|Sea Spray;Sea Elementals;Wave/Deep/Shore Striders|47-49|3|4|4|4|2|4|73
vg138|48|54|B|Azshara|Northwest Timbermaw areas|Timbermaw Furbolgs|48-54|4|3|4|4|3|3|70
vg139|48|54|B|Felwood|Roadside pockets|Wolves;Bears|48-54|4|2|4|4|3|3|70
vg140|48|54|B|Felwood|Roadside beast pockets|Wolves;Bears;Toxic Horrors nearby|48-54|3|3|4|3|4|3|66
vg141|49|54|B|Azshara|Northern peninsula|Thunderhead Hippogryphs|49-54|4|2|4|4|3|3|70
vg142|50|55|B|Un'Goro Crater|Marshal's Refuge outskirts and raptor packs|Venomhide Ravasaurs;Gorillas;Pterrordaxes|50-55|4|4|4|4|2|3|77
vg143|50|55|B|Western Plaguelands|Felstone Field / Dalson's Tears approaches|Skeletons and undead farmers|50-54|4|4|4|4|3|3|76
vg144|50|54|B|Azshara|Naga shore|Nagas|50-54|3|3|4|4|5|3|74
vg145|50|54|B|Felwood|Irontree Woods and cavern|Warpwood Elementals|50-54|4|4|4|4|4|3|74
vg146|50|54|B|Felwood|Irontree Cavern and woods|Warpwood Elementals|50-54|4|3|4|4|4|3|70
vg147|50|52|B|Western Plaguelands|Felstone Field|Skeletons / undead|50-52|4|3|4|4|3|3|70
vg148|51|56|H|Azshara|Valormok-north loops|Hippogryphs;Naga;Legashi Satyrs|51-56|3|2|4|4|5|3|70
vg149|51|56|B|Burning Steppes|Ruins and dragonkin/whelp pockets|Flamekin Imps;Black Dragon Whelps;Blackrock mobs|50-56|3|4|4|3|4|4|66
vg150|52|60|H|Blackrock Depths|Jail / quest-trigger area|Dark Iron Dwarves;quest-spawned elite dwarves|52-60|5|3|4|5|5|4|96
vg151|52|56|B|Western Plaguelands|Sorrow Hill|Skeletal Flayers;Slavering Ghouls;undead|52-56|4|2|4|4|4|3|75
vg152|52|56|B|Western Plaguelands|Sorrow Hill southeast of Andorhal|Undead|52-56|4|3|4|4|3|3|70
vg153|52|58|B|Winterspring|Ice Thistle Hills|Ice Thistle Yetis|52-58|4|3|4|4|3|3|70
vg154|53|58|B|Felwood|Felpaw Village|Deadwood Furbolgs|53-55|4|3|4|4|4|3|76
vg155|53|56|B|Azshara|Blood Elf camps|Blood Elves|53-56|3|2|4|4|4|3|72
vg156|53|58|B|Azshara|Legash Encampment / Blood Elf camps|Legashi Satyrs;Blood Elves|53-56|3|3|4|4|4|2|72
vg157|53|55|B|Felwood|Felpaw Village|Deadwood Furbolgs|53-55|4|4|4|4|3|3|70
vg158|54|60|B|Winterspring|Lake south of Everlook|Ghosts around lake|54-60|4|3|4|4|3|4|80
vg159|54|59|B|Winterspring|Lake Kel'Theril ruins|Highborne ghosts|54-60|4|3|4|4|4|3|78
vg160|54|55|B|Silithus|East of Cenarion Hold|Spiders;Scorpids;Strikers|54-55|4|2|4|4|2|3|70
vg161|54|59|B|Silithus|East of Cenarion Hold|Spiders;Scorpids;Stonelash Strikers|54-55|3|3|4|3|4|2|68
vg162|55|60|H|Winterspring|Everlook-adjacent furbolg/beast loops|Winterfall Furbolgs;Bears;Frostsabers|55-60|4|4|4|4|3|3|74
vg163|55|58|B|Western Plaguelands|Northridge Lumber Camp|Scarlet Lumberjacks|55-58|4|2|4|4|4|3|73
vg164|55|58|B|Deadwind Pass|The Vice|Deadwind Ogres|55-58|4|3|4|4|4|2|70
vg165|55|60|B|Eastern Plaguelands|Plaguewood / Marris Stead edges|Plaguebats;Plaguehounds;Carrion Grubs|55-60|3|4|4|4|3|3|70
vg166|56|60|B|Burning Steppes|Blackrock Stronghold exterior|Blackrock Orcs and Warlocks|56-60|4|5|4|4|5|3|72
vg167|56|60|B|Winterspring|Frostsaber Rock and owl/bear loops|Shardtooth Bears;Frostsabers;Moonkin;Chimaeras|56-60|3|3|4|3|3|3|68
vg168|57|60|B|Silithus|Northwest elemental camps|Dust Stormers;Desert Rumblers|57-60|4|2|4|4|3|3|82
vg169|57|60|B|Silithus|Northwest corner|Earth and Air Elementals|57-60|4|2|4|4|3|3|70
vg170|58|60|B|Western Plaguelands|Hearthglen work areas|Scarlet Workers|58-60|4|5|4|4|4|4|82
vg171|58|60|B|Lower Blackrock Spire|Initial lower areas / ogre route|Blackrock orcs;spiders;ogres|58-60|4|3|4|4|5|3|79
vg172|58|60|B|Western Plaguelands|Hearthglen outskirts|Scarlet Workers|58-60|4|4|4|4|4|3|76
vg173|58|60|B|Eastern Plaguelands|Tyr's Hand outer edges|Scarlet elites / Scarlet humans|58-60|3|3|4|3|5|3|68
vg174|59|60|B|Silithus|Twilight camps near Cenarion Hold|Twilight Cultists|58-60|4|4|4|4|3|4|78
vg175|60|60|B|Zul'Gurub|Crocodile bridge / river pulls|Zulian Crocolisks|60|5|3|4|5|3|3|85
vg176|60|60|B|Dire Maul East|Lasher drop-down area|Whip Lashers;Wildspawn Imps|60|5|2|4|4|3|3|84
vg177|60|60|B|Silithus|Twilight / elemental areas|Twilight cultists;Air/Earth Elementals|58-60|3|5|4|3|3|4|60
vg178|60|60|B|Eastern Plaguelands|Tyr's Hand|Scarlet Elites|57-60 elites|3|3|4|3|5|3|58
]=]

GrindLlama_Locations = {}
for line in string.gmatch(rawData, "[^\r\n]+") do
    local row = SplitFields(line)
    table.insert(GrindLlama_Locations, {
        id = row[1], name = row[6], zone = row[5], subzone = row[6],
        minLevel = tonumber(row[2]), maxLevel = tonumber(row[3]), idealMin = tonumber(row[2]), idealMax = tonumber(row[3]), faction = FactionName(row[4]),
        mobTypes = SplitList(row[7]), mobLevelRange = row[8],
        density = tonumber(row[9]), danger = tonumber(row[10]), travel = tonumber(row[11]), xp = tonumber(row[12]), gold = tonumber(row[13]),
        competition = tonumber(row[14]), priorityScore = tonumber(row[15])
    })
end
