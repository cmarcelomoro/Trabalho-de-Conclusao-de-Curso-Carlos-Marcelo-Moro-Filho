#pragma once
#include "Leitura.hpp"
#include "Utilidades.hpp"
#include <U8g2lib.h>
#ifdef U8X8_HAVE_HW_SPI
#include <SPI.h>
#endif
#ifdef U8X8_HAVE_HW_I2C
#include <Wire.h>
#endif

class Display{
   
    private:
        U8G2_ST7567_ENH_DG128064_F_4W_SW_SPI u8g2;

    
    public:
        Display() : u8g2(U8G2_R0,  18,  23, 12, 5, 13){}

    void iniciarDisplay() {
        u8g2.begin();
    }  

    void renderizarLeitura(const Leitura& leitura, const String& conexao) {	
        u8g2.clearBuffer();	
        u8g2.setFont(u8g2_font_ncenB08_tr);	
        u8g2.drawStr(4,10,conexao.c_str());
        u8g2.drawHLine(0,14,127);
        u8g2.drawStr(4,25,"");

        if(leitura.Brinco){
            u8g2.drawStr(4,35,Utilidades::brincoString(leitura.Brinco).c_str());
        }else{
            u8g2.drawStr(4,35,"Aguardando Leitura");
        }
        u8g2.drawStr(4,55,"");
        u8g2.sendBuffer();
    }
      void renderizarTexto(String texto) {
        u8g2.clearBuffer();			
        u8g2.setFont(u8g2_font_ncenB08_tr);	

        u8g2.drawStr(4,35,texto.c_str());
        
        u8g2.sendBuffer();
    }
};