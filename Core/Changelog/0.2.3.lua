local W = unpack((select(2, ...))) ---@type WindTools

W.Changelog[203] = {
	RELEASE_DATE = "2026/08/27",
	IMPORTANT = {
		["zhCN"] = {
			"快速标记栏现在始终可见（仅宠物战斗中隐藏）。",
		},
		["zhTW"] = {
			"快速標記欄現在始終可見（僅寵物戰鬥中隱藏）。",
		},
		["enUS"] = {
			"The Raid Markers bar is now always visible (hidden only in pet battles).",
		},
		["koKR"] = {
			"Raid Markers 바가 항상 표시됩니다(애완동물 전투에서만 숨겨짐).",
		},
		["ruRU"] = {
			"Панель Raid Markers теперь всегда видна (скрывается только в битвах питомцев).",
		},
	},
	NEW = {
		["zhCN"] = {
			"快速标记栏支持在 EllesmereUI 解锁模式下拖动定位，位置保存在账号级别，默认位置在聊天面板上方。",
			"快速标记页面顶部新增按钮大小和按钮间距设置。",
		},
		["zhTW"] = {
			"快速標記欄支援在 EllesmereUI 解鎖模式下拖動定位，位置儲存在帳號層級，預設位置在聊天面板上方。",
			"快速標記頁面頂部新增按鈕大小和按鈕間距設定。",
		},
		["enUS"] = {
			"The Raid Markers bar can now be dragged in EllesmereUI's Unlock Mode; the position is saved account-wide and defaults to above the chat panel.",
			"Added Button Size and Button Spacing controls at the top of the Raid Markers page.",
		},
		["koKR"] = {
			"Raid Markers 바를 EllesmereUI 잠금 해제 모드에서 드래그하여 배치할 수 있습니다. 위치는 계정 수준으로 저장되며 기본 위치는 채팅 패널 위입니다.",
			"Raid Markers 페이지 상단에 버튼 크기와 버튼 간격 설정을 추가했습니다.",
		},
		["ruRU"] = {
			"Панель Raid Markers теперь можно перетаскивать в режиме разблокировки EllesmereUI; позиция сохраняется на уровне аккаунта, по умолчанию — над панелью чата.",
			"В начало страницы Raid Markers добавлены настройки размера кнопок и отступов между ними.",
		},
	},
	IMPROVEMENT = {
		["zhCN"] = {
			"选项页面与原版 WindTools 分类结构对齐：战斗和单位框体各为一个页面，模块分组内联展示，未移植模块的选项以禁用状态显示。",
			"聊天条文字样式按钮现在根据文字自动调整宽高。",
			"快速焦点登录后立即生效，无需重新开关。",
		},
		["zhTW"] = {
			"選項頁面與原版 WindTools 分類結構對齊：戰鬥和單位框架各為一個頁面，模組分組內聯展示，未移植模組的選項以停用狀態顯示。",
			"聊天條文字樣式按鈕現在根據文字自動調整寬高。",
			"快速焦點登入後立即生效，無需重新開關。",
		},
		["enUS"] = {
			"Options pages now match the original WindTools category layout: Combat and Unit Frames are single pages with module groups inline; unported module options render disabled.",
			"Chat Bar TEXT style buttons now auto-size to their labels.",
			"Quick Focus now works immediately after login without toggling it off and on.",
		},
		["koKR"] = {
			"옵션 페이지가 원본 WindTools 범주 레이아웃과 일치합니다: 전투와 유닛 프레임이 각각 하나의 페이지이며 모듈 그룹이 인라인으로 표시되고 포팅되지 않은 모듈 옵션은 비활성화 상태로 표시됩니다.",
			"채팅 바 TEXT 스타일 버튼이 레이블에 맞게 크기를 자동 조정합니다.",
			"Quick Focus가 로그인 후 다시 켜고 끌 필요 없이 즉시 작동합니다.",
		},
		["ruRU"] = {
			"Страницы настроек соответствуют оригинальной структуре категорий WindTools: «Бой» и «Юнит-фреймы» — по одной странице со встроенными группами модулей; настройки неперенесённых модулей отображаются отключёнными.",
			"Кнопки панели чата в стиле TEXT автоматически подстраивают размер под текст.",
			"Quick Focus теперь работает сразу после входа, без повторного переключения.",
		},
	},
}
