playersData = { --До 12 игроков, далее все игроки будут скрыты, но уведомления будут в чате
    -- игроки для проверки на онлайн {"ник", пол (M/W), сообщение, онлайн, "10:40" - не обязательна, временно не трогать}
    {"webdevery", "M", "Царь батюшка на сервере", false, "10:40"}, -- 1
    {"Amsi", "M", "Машина подъехала", false, "10:40"}, -- 1

    --{"", "W", nil, false},
}

TableTitle = "&4[Мониторинг]"

maxEnergyFile = "/home/data/energyInfo.txt" -- Путь к файлу для сохранения максимальной энергии
reactorCntFile = "/home/data/reactorInfo.txt" -- Путь к файлу для сохранения кол-ва реакторов
tpsFile = "/tmp/TF"

debug = true

frameNames = { usersFrame = 'usersFrame'} 
frameBoxes = {}

cPos = { x = -1, y = -1 }