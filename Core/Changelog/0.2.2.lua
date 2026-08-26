local W = unpack((select(2, ...))) ---@type WindTools

W.Changelog[202] = {
	RELEASE_DATE = "2026/08/22",
	IMPORTANT = {
		["zhCN"] = {},
		["zhTW"] = {},
		["enUS"] = {},
		["koKR"] = {},
		["ruRU"] = {},
	},
	NEW = {
		["zhCN"] = {
			"快速标记和快速焦点选项页面新增页面内的启用开关。",
			"已禁用但已迁移的选项页面现在可以直接打开，便于重新启用。",
		},
		["zhTW"] = {
			"快速標記和快速焦點選項頁面新增頁面內的啟用開關。",
			"已停用但已遷移的選項頁面現在可以直接開啟，便於重新啟用。",
		},
		["enUS"] = {
			"Added an in-page Enable toggle to the Raid Markers and Quick Focus option pages.",
			"Disabled pages of ported modules can now be opened directly for re-enabling.",
		},
		["koKR"] = {
			"Raid Markers 및 Quick Focus 옵션 페이지에 페이지 내 활성화 토글을 추가했습니다.",
			"포팅된 모듈의 비활성화된 페이지를 다시 활성화하기 위해 직접 열 수 있습니다.",
		},
		["ruRU"] = {
			"На страницы настроек Raid Markers и Quick Focus добавлен переключатель включения.",
			"Отключённые страницы перенесённых модулей теперь можно открыть напрямую для повторного включения.",
		},
	},
	IMPROVEMENT = {
		["zhCN"] = {
			"修复快速标记按钮图标被背景遮挡而显示为黑色方块的问题。",
			"修复快速焦点在宿主单位框体创建较晚时无法生效的问题，启用后会自动延迟重试扫描。",
			"侧边栏中已禁用模块的标签和电源图标改为更醒目的样式。",
		},
		["zhTW"] = {
			"修復快速標記按鈕圖示被背景遮擋而顯示為黑色方塊的問題。",
			"修復快速焦點在宿主單位框體建立較晚時無法生效的問題，啟用後會自動延遲重試掃描。",
			"側邊欄中已停用模組的標籤和電源圖示改為更醒目的樣式。",
		},
		["enUS"] = {
			"Fixed Raid Markers button icons being hidden behind their backdrops (shown as black squares).",
			"Fixed Quick Focus not applying to host unit frames created late after login; delayed rescan is now scheduled after enabling.",
			"Sidebar labels and power icons for disabled modules are now more visible.",
		},
		["koKR"] = {
			"버튼 아이콘이 배경에 가려 검은 사각형으로 표시되는 Raid Markers 문제를 수정했습니다.",
			"로그인 후 늦게 생성되는 호스트 유닛 프레임에 Quick Focus가 적용되지 않는 문제를 수정했습니다. 활성화 후 지연 재스캔이 예약됩니다.",
			"비활성화된 모듈의 사이드바 레이블과 전원 아이콘이 더 잘 보이도록 개선했습니다.",
		},
		["ruRU"] = {
			"Исправлено скрытие значков кнопок Raid Markers за фонами (отображались чёрными квадратами).",
			"Исправлено применение Quick Focus к юнит-фреймам хоста, создаваемым с задержкой после входа; теперь планируется отложенное повторное сканирование.",
			"Метки боковой панели и значки питания отключённых модулей стали заметнее.",
		},
	},
}
