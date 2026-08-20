local W = unpack((select(2, ...))) ---@type WindTools

W.Changelog[200] = {
	RELEASE_DATE = "2026/08/20",
	IMPORTANT = {
		["zhCN"] = {
			"快速焦点现在默认启用，可通过 [单位框体] - [快速焦点] 页面调整或关闭。",
		},
		["zhTW"] = {
			"快速焦點現在預設啟用，可透過 [單位框體] - [快速焦點] 頁面調整或關閉。",
		},
		["enUS"] = {
			"QuickFocus is now enabled by default; adjust or disable it on the [Unit Frames] - [Quick Focus] page.",
		},
		["koKR"] = {
			"QuickFocus는 이제 기본적으로 활성화되어 있으며 [유닛 프레임] - [Quick Focus] 페이지에서 조정하거나 비활성화할 수 있습니다.",
		},
		["ruRU"] = {
			"QuickFocus теперь включён по умолчанию; настройте или отключите его на странице [Юнит-фреймы] - [Quick Focus].",
		},
	},
	NEW = {
		["zhCN"] = {
			"完成快速标记迁移：支持目标/世界标记、清除标记、就位确认、战斗日志和拉怪倒计时。",
			"完成快速焦点迁移：支持修饰键点击聚焦鼠标指向目标，并可选自动设置目标标记。",
		},
		["zhTW"] = {
			"完成快速標記遷移：支援目標/世界標記、清除標記、就位確認、戰鬥記錄和拉怪倒數。",
			"完成快速焦點遷移：支援修飾鍵點擊聚焦滑鼠指向目標，並可選自動設定目標標記。",
		},
		["enUS"] = {
			"Ported Raid Markers with target/world markers, clear actions, ready check, combat logging, and pull countdown.",
			"Ported QuickFocus for modifier-click focus on mouseover units, with optional target marking.",
		},
		["koKR"] = {
			"대상/월드 마커, 마커 지우기, 준비 확인, 전투 기록 및 풀 카운트다운을 지원하는 Raid Markers를 포팅했습니다.",
			"마우스오버 유닛에 수정 키 클릭으로 집중하고 선택적으로 대상을 표시하는 QuickFocus를 포팅했습니다.",
		},
		["ruRU"] = {
			"Перенесены Raid Markers: метки цели/мира, очистка меток, проверка готовности, журнал боя и обратный отсчёт пула.",
			"Перенесён QuickFocus для фокусировки на наведённом юните по клику с модификатором и опциональной установкой метки.",
		},
	},
	IMPROVEMENT = {
		["zhCN"] = {
			"修复快速标记在未安装 BigWigs/DBM 时倒计时取消功能无效的问题。",
		},
		["zhTW"] = {
			"修復快速標記在未安裝 BigWigs/DBM 時倒數取消功能無效的問題。",
		},
		["enUS"] = {
			"Fixed Raid Markers pull countdown cancel not working when BigWigs/DBM is not installed.",
		},
		["koKR"] = {
			"BigWigs/DBM이 설치되지 않은 경우 풀 카운트다운 취소가 작동하지 않는 Raid Markers 문제를 수정했습니다.",
		},
		["ruRU"] = {
			"Исправлена отмена обратного отсчёта Raid Markers при отсутствии BigWigs/DBM.",
		},
	},
}
