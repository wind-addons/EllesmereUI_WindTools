local W = unpack((select(2, ...))) ---@type WindTools

W.Changelog[205] = {
	RELEASE_DATE = "2026/08/31",
	IMPORTANT = {
		["zhCN"] = {
			"修复快速焦点在扫描框架时报错的问题：暴雪内置伤害统计的条目会覆写 GetName 并返回非字符串值，现在会安全跳过。",
			"修复切换区域时快速焦点造成的卡顿：合并区域切换期间连发的全量框架扫描，并推迟到加载屏结束后执行。",
		},
		["zhTW"] = {
			"修正快速焦點掃描框架時報錯的問題：暴雪內建傷害統計的條目會覆寫 GetName 並回傳非字串值，現在會安全跳過。",
			"修正切換區域時快速焦點造成的卡頓：合併區域切換期間連發的全量框架掃描，並延後到載入畫面結束後執行。",
		},
		["enUS"] = {
			"Fixed Quick Focus errors while scanning frames: Blizzard's built-in damage meter overrides GetName() on its bars with a non-string value; such frames are now skipped safely.",
			"Fixed Quick Focus freezes when crossing zones: bursty full-frame scans during zone transitions are now coalesced and deferred until the loading screen is gone.",
		},
		["koKR"] = {
			"빠른 집중이 프레임 스캔 중 오류를 일으키던 문제를 수정했습니다: 블리자드 기본 데미지 미터가 자체 바의 GetName()을 문자열이 아닌 값으로 재정의하여 발생했으며, 이제 해당 프레임을 안전하게 건너뜁니다.",
			"지역 전환 시 빠른 집중으로 인한 멈춤 현상을 수정했습니다: 지역 전환 중 반복 실행되던 전체 프레임 스캔을 통합하고 로딩 화면이 끝난 후 실행하도록 변경했습니다.",
		},
		["ruRU"] = {
			"Исправлены ошибки Быстрой фокуса при сканировании фреймов: встроенный измеритель урона Blizzard переопределяет GetName() на своих полосах, возвращая не строку; такие фреймы теперь безопасно пропускаются.",
			"Исправлены зависания Быстрой фокуса при смене зоны: повторные полные сканирования фреймов во время перехода между зонами объединяются и выполняются после исчезновения экрана загрузки.",
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
			"快速焦点：战斗中新出现的框架会在脱战后自动补上焦点点击属性；战斗中修改或停用设置后的更新与清理也会在脱战后正确执行；修改修饰键或鼠标键后无需重载界面即可对已有框架生效。",
			"快速焦点改用 ClickCastFrames 注册表机制（Clique/Cell 同款）：oUF 系框架与团队框架一经创建即可用；为性能考虑不再全量扫描 UI，暴雪原生框架等未注册框架不再支持。",
		},
		["zhTW"] = {
			"快速焦點：戰鬥中新出現的框架會在脫離戰鬥後自動補上焦點點擊屬性；戰鬥中修改或停用設定後的更新與清理也會在脫離戰鬥後正確執行；修改修飾鍵或滑鼠鍵後無需重載介面即可對已有框架生效。",
			"快速焦點改用 ClickCastFrames 註冊表機制（Clique/Cell 同款）：oUF 系框架與團隊框架一經建立即可用；為效能考量不再全量掃描 UI，暴雪原生框架等未註冊框架不再支援。",
		},
		["enUS"] = {
			"Quick Focus: frames appearing mid-combat now receive their focus-click attribute right after combat ends; setting changes and cleanup started during combat are also completed after combat; changing the modifier or mouse button now applies to existing frames without a UI reload.",
			"Quick Focus now uses the ClickCastFrames registry (the same mechanism Clique and Cell use): oUF-based and raid frames work the instant they are created. For performance it no longer scans the UI, so frames that never register, such as Blizzard's stock unit frames, are no longer covered.",
		},
		["koKR"] = {
			"빠른 집중: 전투 중 나타난 프레임은 전투 종료 직후 초점 클릭 속성을 받으며, 전투 중 시작된 설정 변경 및 정리도 전투 종료 후 완료됩니다. 수정 키나 마우스 버튼 변경 시 UI 재시작 없이 기존 프레임에 적용됩니다.",
			"빠른 집중이 Clique과 Cell과 동일한 ClickCastFrames 레지스트리를 사용합니다: oUF 기반 프레임과 공격대 프레임이 생성되는 즉시 동작합니다. 성능을 위해 UI 전체 스캔을 제거하여 블리자드 기본 프레임처럼 등록되지 않는 프레임은 더 이상 지원되지 않습니다.",
		},
		["ruRU"] = {
			"Быстрая фокус: фреймы, появившиеся в бою, получают атрибут фокус-клика сразу после его окончания; изменения настроек и очистка, начатые в бою, также завершаются после боя; смена модификатора или кнопки мыши теперь применяется к существующим фреймам без перезагрузки интерфейса.",
			"Быстрая фокус теперь использует реестр ClickCastFrames (тот же механизм, что у Clique и Cell): фреймы на базе oUF и рейдовые фреймы работают сразу после создания. Ради производительности полное сканирование интерфейса удалено, поэтому незарегистрированные фреймы, такие как стандартные фреймы Blizzard, больше не поддерживаются.",
		},
	},
}
