# 本机使用 rsync
rsync -avh --exclude 'log/' --exclude='tmp/' --exclude='.idea/' -e ssh /Users/yangdegui/my_service/games/survivor_server root@82.156.77.48:/data/server/
