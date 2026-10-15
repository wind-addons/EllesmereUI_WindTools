local W = unpack((select(2, ...))) ---@type WindTools

W.Changelog[207] = {
	RELEASE_DATE = "2026/10/15",
	IMPORTANT = {
		["zhCN"] = {
			"现已支持《魔兽世界》12.1.5（接口版本 120105）。",
		},
		["zhTW"] = {
			"現已支援《魔獸世界》12.1.5（介面版本 120105）。",
		},
		["enUS"] = {
			"EllesmereUI_WindTools now supports Patch 12.1.5 (interface 120105).",
		},
		["koKR"] = {
			"월드 오브 워크래프트 12.1.5(인터페이스 120105)를 지원합니다.",
		},
		["ruRU"] = {
			"Теперь поддерживается патч 12.1.5 (interface 120105).",
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
		["zhCN"] = {
			"修复 EllesmereUI 未完整加载时弹出 L 为 nil 的问题；现在仅显示一条明确提示，不再连锁报错。",
		},
		["zhTW"] = {
			"修復 EllesmereUI 未完整載入時彈出 L 為 nil 的問題；現在僅顯示一條明確提示，不再連鎖報錯。",
		},
		["enUS"] = {
			"Fixed the \"L is nil\" error when EllesmereUI fails to load: initialization problems now show one clear message instead of cascading Lua errors.",
		},
		["koKR"] = {
			"EllesmereUI가 완전히 로드되지 않을 때 L이 nil이라는 오류가 표시되던 문제를 수정했습니다. 이제 명확한 메시지가 한 번만 표시되며 연쇄 오류가 발생하지 않습니다.",
		},
		["ruRU"] = {
			"Исправлена ошибка «L is nil» при неполной загрузке EllesmereUI: вместо цепочки ошибок Lua теперь выводится одно понятное сообщение.",
		},
	},
}
