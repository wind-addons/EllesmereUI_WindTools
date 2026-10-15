local W = unpack((select(2, ...))) ---@type WindTools

W.Changelog[208] = {
	RELEASE_DATE = "2026/10/15",
	IMPORTANT = {
		["zhCN"] = {
			"修复适配新版 EllesmereUI 语言引擎后非当前语言的翻译文件加载报错（L 为 nil）的问题。",
		},
		["zhTW"] = {
			"修復適配新版 EllesmereUI 語言引擎後非當前語言的翻譯檔案載入報錯（L 為 nil）的問題。",
		},
		["enUS"] = {
			"Fixed load errors (\"L is nil\") in inactive-locale translation files with the new EllesmereUI locale engine.",
		},
		["koKR"] = {
			"새로운 EllesmereUI 언어 엔진에서 비활성 로케일 번역 파일이 로드되며 오류(L이 nil)가 발생하던 문제를 수정했습니다.",
		},
		["ruRU"] = {
			"Исправлена ошибка загрузки («L is nil») в файлах перевода неактивных локалей с новым языковым движком EllesmereUI.",
		},
	},
	NEW = {
		["zhCN"] = {},
		["zhTW"] = {},
		["enUS"] = {},
		["koKR"] = {},
		["ruRU"] = {},
	},
	IMPROVEMENT = {
		["zhCN"] = {},
		["zhTW"] = {},
		["enUS"] = {},
		["koKR"] = {},
		["ruRU"] = {},
	},
}
