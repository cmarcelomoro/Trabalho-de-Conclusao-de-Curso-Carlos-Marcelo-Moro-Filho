#pragma once
#include <Esp.h>


struct Leitura {
    uint64_t Brinco;
  
    Leitura() = default;

    void atualizar(uint64_t brinco){
        Brinco = brinco;
      
    }
};

