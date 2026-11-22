
#pragma once
#include <Esp.h>
class Utilidades{
    public:
        static String obterDataAtual(){
            struct tm timeinfo;


            if(!getLocalTime(&timeinfo)){
                return "Sem Hora";
            }


            char buffer[30];
            strftime(buffer,sizeof(buffer),"%d/%m/%Y %H:%M:%S",&timeinfo);
            return String(buffer);
        }

        static String brincoString(uint64_t valor) {
            return String((unsigned long long)valor);
        }
};
