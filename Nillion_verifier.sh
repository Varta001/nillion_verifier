#!/bin/bash

BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
NC='\033[0m'

# Проверка поддержки корейского языка
check_korean_support() {
    if locale -a | grep -q "ko_KR.utf8"; then
        return 0  # Поддержка корейского языка установлена
    else
        return 1  # Поддержка корейского языка не установлена
    fi
}

# Проверка на наличие корейского языка
if check_korean_support; then
    echo -e "${CYAN}한글있긔 설치넘기긔.${NC}"
else
    echo -e "${CYAN}한글없긔, 설치하겠긔.${NC}"
    sudo apt-get install language-pack-ko -y
    sudo locale-gen ko_KR.UTF-8
    sudo update-locale LANG=ko_KR.UTF-8 LC_MESSAGES=POSIX
    echo -e "${CYAN}설치 완료했긔.${NC}"
}

install_nillion() {
# Установка основных пакетов
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${CYAN}sudo apt update${NC}"
sudo apt update

echo -e "${CYAN}sudo apt upgrade -y${NC}"
sudo apt upgrade -y

echo -e "${CYAN}sudo apt -qy install curl git jq lz4 build-essential screen${NC}"
sudo apt -qy install curl git jq lz4 build-essential screen

echo -e "${BOLD}${CYAN}Проверка установки Docker...${NC}"
if ! command_exists docker; then
    echo -e "${RED}Docker не установлен. Устанавливаю Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    echo -e "${CYAN}Docker успешно установлен.${NC}"
else
    echo -e "${CYAN}Docker уже установлен.${NC}"
fi

echo -e "${CYAN}docker version${NC}"
docker version

echo -e "${CYAN}Установка образа nillion-accuser...${NC}"
docker pull nillion/retailtoken-accuser:v1.0.1

echo -e "${CYAN}Создание директории accuser...${NC}"
mkdir -p nillion/accuser

echo -e "${CYAN}Запуск контейнера nillion-accuser...${NC}"
docker run -v ./nillion/accuser:/var/tmp nillion/retailtoken-accuser:v1.0.1 initialise

echo -e "${BOLD}${YELLOW}1. Посетите: https://verifier.nillion.com/ (CTRL + клик для перехода).${NC}"
echo -e "${BOLD}${YELLOW}2. Нажмите 'connect Keplr Wallet' в правом верхнем углу для входа.${NC}"
echo -e "${BOLD}${YELLOW}3. Перейдите на https://faucet.testnet.nillion.com/ и получите токены для созданного кошелька.${NC}"
echo -e "${BOLD}${YELLOW}4. Через час снова выполните команду для продолжения.${NC}"
}

verify_nillion() {
# Проверка выполнения предыдущих шагов пользователем
echo -ne "${MAGENTA}Вы завершили все шаги?${NC} [y/n] :"
read response
if [[ "$response" =~ ^[yY]$ ]]; then
    echo -e "${BOLD}${CYAN}Обновление...${NC}"
    sudo apt update -y
    echo -e "${BOLD}${CYAN}Сейчас произойдет несколько действий, нажмите CTRL + C три раза, чтобы остановить.${NC}"
	sudo docker run -v ./nillion/accuser:/var/tmp nillion/retailtoken-accuser:latest accuse --rpc-endpoint "https://testnet-nillion-rpc.lavenderfive.com/" --block-start "$(curl -s https://testnet-nillion-rpc.lavenderfive.com/abci_info | jq -r '.result.response.last_block_height')"
else
	echo -e "${RED}${BOLD}А${NC}"
	echo -e "${YELLOW}${BOLD}Почему${NC}"
	echo -e "${BLUE}${BOLD}вы не сделали это?${NC}"
	echo -e "${MAGENTA}${BOLD}tlqkf${NC}"  # Неясное слово, возможно, опечатка?
	echo -e "${GREEN}${BOLD}Почему не сделали?${NC}"
	echo -e "${CYAN}${BOLD}Пожалуйста!${NC}"
	exit 1
fi

echo -e "${MAGENTA}Если не появилось Registered : TRUE, удалите кошелек и Nillion, затем повторите процесс.${NC}"
}

restart_nillion() {
# Перезапуск узла Nillion
echo -e "${CYAN}Перезапуск узла...${NC}"

docker ps | grep nillion | awk '{print $1}' | xargs docker stop

docker ps -a | grep nillion | awk '{print $1}' | xargs docker restart

echo -e "${CYAN}Готово.${NC}"
}

uninstall_nillion() {
# Удаление узла Nillion и Docker контейнеров
echo -e "${CYAN}Остановка и удаление контейнеров...${NC}"

docker ps | grep nillion | awk '{print $1}' | xargs docker stop

docker ps -a | grep nillion | awk '{print $1}' | xargs docker rm

docker rmi `docker images | awk '$1 ~ /nillion/ {print $1, $3}'`

echo -e "${CYAN}Готово.${NC}"
}

# Главное меню
echo && echo -e "${BOLD}${MAGENTA}Автоматический скрипт установки узла Nillion Accuser${NC} by 비욘세제발죽어"
echo -e "${CYAN}Выберите действие и выполните его.${NC}
 ———————————————————————
 ${GREEN} 1. Установить основные файлы и запустить Nillion ${NC}
 ${GREEN} 2. Верификация Nillion ${NC}
 ${GREEN} 3. Перезапуск Nillion ${NC}
 ${GREEN} 4. Удаление Nillion ${NC}
 ———————————————————————" && echo

# Ожидание ввода пользователя
echo -ne "${BOLD}${MAGENTA}Какое действие вы хотите выполнить? Введите номер: ${NC}"
read -e num

case "$num" in
1)
    install_nillion
    ;;
2)
    verify_nillion
    ;;
3)
    restart_nillion
    ;;
4)
    uninstall_nillion
    ;;
*)
    echo -e "${BOLD}${RED}Неверный ввод! Попробуйте еще раз.${NC}"
esac
