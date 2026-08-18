import os
import re
from slpp import slpp as lua

# Only root-level semantic-version files are current releases; Previous/ contains historical records.
latest_version = None
for file in os.listdir("Core/Changelog"):
    if not file.endswith(".lua") or file == "_template.lua":
        continue
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", os.path.splitext(file)[0])
    if not match:
        continue
    version = tuple(int(part) for part in match.groups())
    if latest_version is None or version > latest_version:
        latest_version = version

# 提取更新记录的 lua 字符串
changelog_version = ".".join(str(part) for part in latest_version)
changelog_path = "Core/Changelog/{}.lua".format(changelog_version)
with open(changelog_path, "r", encoding="utf8") as f:
    changelog_lua_string = f.read().replace("\n", "")

start_index = changelog_lua_string.find("{")
changelog_lua_string = changelog_lua_string[start_index:]

# 解析 lua table 到 Python dict
changelog = lua.decode(changelog_lua_string)

locales = [
    {
        "language": "enUS",
        "VERSION": "Version",
        "IMPORTANT": "Important",
        "NEW": "New",
        "IMPROVEMENT": "Improvement",
        "RELEASED_STRING": "{} Released",
    },
    {
        "language": "zhCN",
        "VERSION": "版本",
        "IMPORTANT": "重要",
        "NEW": "新增",
        "IMPROVEMENT": "改善",
        "RELEASED_STRING": "{} 发布",
    },
    {
        "language": "zhTW",
        "VERSION": "版本",
        "IMPORTANT": "重要",
        "NEW": "新增",
        "IMPROVEMENT": "改善",
        "RELEASED_STRING": "{} 發布",
    },
    {
        "language": "koKR",
        "VERSION": "버전",
        "IMPORTANT": "중요 사항",
        "NEW": "신규 사항",
        "IMPROVEMENT": "개선 사항",
        "RELEASED_STRING": "{} Released",
    },
    {
        "language": "ruRU",
        "VERSION": "Версия",
        "IMPORTANT": "Важные",
        "NEW": "Новые",
        "IMPROVEMENT": "Улучшения",
        "RELEASED_STRING": "{} Релиз",
    },
]

parts = [
    {
        "emoji": "❗",
        "name": "IMPORTANT",
    },
    {
        "emoji": "✳️",
        "name": "NEW",
    },
    {
        "emoji": "💪",
        "name": "IMPROVEMENT",
    },
]

with open("CHANGELOG.md", "w", encoding="utf8") as f:
    for locale in locales:
        f.write("# {}: {}\n".format(locale["VERSION"], changelog_version))
        f.write(locale["RELEASED_STRING"].format(changelog["RELEASE_DATE"]) + "\n")

        for part in parts:
            try:
                if len(changelog[part["name"]]["zhTW"]) > 0:
                    f.write("## {} {}\n".format(part["emoji"], locale[part["name"]]))
                    for line in changelog[part["name"]][locale["language"]]:
                        f.write("- {}\n".format(line))
            except:
                pass

        f.write("\n------\n")
