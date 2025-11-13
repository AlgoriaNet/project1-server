# 本机使用 rsync
# rsync -avh --exclude 'log/' --exclude='tmp/' --exclude='.idea/' -e ssh /Users/yangdegui/my_service/games/survivor_server root@43.162.120.137:/data/server/
rsync -avh --exclude 'log/' --exclude='tmp/' --exclude='.idea/' -e ssh /Volumes/WD_SSD/UnityProjects/Rogue/project1-server root@43.162.120.137:/data/server/