# Alcatraz-Soil
Amiga500 40k intro. Created with vscode-amiga-debug by bartman/abyss


   release name: Soil                         
           type: Amiga 500 - 40k intro        
   release date: 19.01.2024                   
                                              
   code + music: Virgill                      
            gfx: Critikill                    
                                              
   Amiga  ASCII: NE7                          
                                              
   rendering worlds,  needs +512k to run      
                                              
                                              
   Contact us @ PLK 555-NASE                  
                                              
   I  (Virgill) embarked   on a  delightful   
   8-week  journey  rekindling   my  coding   
   skills on the Amiga. After a whopping 33   
   years, my mind  was practically  a blank   
   slate. It all began when I pondered if a   
   routine,   akin  to  my Windows 4k intro   
   "Xorverse," could somehow find a home on   
   the  Amiga. Excited, I    fired  up  the   
   fantastic VScode-Amiga-debug environment   
   from Abyss, only  to   hit a snag  - the   
   good    old Amiga    could  only  handle   
   rendering   a  maximum   of 2   lines of   
   graphics for those   xor algorithms  per   
   frame.                                     
                                              
   Undeterred, I decided scrolling could be   
   a  solution, and  that's  when the  real   
   challenges surfaced. How on   earth do I   
   create  a copperlist? What's  the secret   
   to waiting for    the beam in  the lower   
   part of the screen? And how in the world   
   do  I turn the graphics upside down? Ah,   
   there's  a modulo   register; let's just   
   brute  force it until   it  looks  good.   
                                              
   Thinking   I could  turn    this into  a   
   complete intro, I needed a music player.   
   Choosing Aklang and  LSP seemed   like a   
   no-brainer,   but  boy,  it gave me more   
   grey hairs than  I anticipated. Shoutout   
   to Platon42 and Leonard for coming to my   
   rescue, helping me run  it smoothly. And   
   yes, I even had  to dabble  in assembler   
   to  coax a   beat counter  out   of LSP,   
   bringing   back  the    basics of  68000   
   assembly.                                  
                                              
   Next   up on  the    list:  sprites.  It   
   couldn't be   that  hard, right?  Wrong!   
   Creating   data  structures  for sprites   
   turned out to be a headache, courtesy of   
   Commodore. I longed  for the  simplicity   
   of the C64. Still, I  somehow managed to   
   showcase  a  spaceship, invaders,  and a   
   border.                                    
                                              
   Enter  Critikill,     whose  involvement   
   injected  new life into the project. His   
   fantastic graphics  and assets  became a   
   tremendous source of inspiration. Thanks   
   a bunch, mate!                             
                                              
   Now, it  was time to tackle the blitter,   
   a  step that   filled    me   with  awe.   
   Brute-forcing       blitter     minterms   
   (resulting  in   the  fire-fx)  was  the   
   initial   approach      until    Leonard   
   enlightened   me  on   an  easier way to   
   calculate them. Blitting  those  bubbles   
   ensued,  discovering   the  comfort   of   
   interleaved bitplanes mode. One blit per   
   bubble   –  how    comfy!  Crafting  the   
   copperlist  for those looping  bitplanes   
   in  two speeds    took a week  of logic.   
   Blitting  over  the  repeating  bitplane   
   borders? Another week :)                   
                                              
   The sine part threw another challenge my   
   way.  In C,  plotting  many dots  wasn't   
   feasible, so back to  asm  it was. Speed   
   increased,  but  occasional jerky  frame   
   drops persisted.  Thanks  to Platon  for   
   the  hint  on the  CIA player and how to   
   fix the waitVBL routine!                   
                                              
   I   could   share     more,   like   the   
   satisfaction when a  simple fade routine   
   finally  worked,  or  the art of filling   
   the  remaining  4k  with a speech sample   
   when coding fatigue set in.                
                                              
   Major  kudos to  the insane Amiga coders   
   who've mastered every bit  and trick  in   
   this machine. It's downright crazy hard!   
                                              
   Special thanks to:                         
                                              
   Soundy  for  the  quick   gradientmaster   
   update.                                    
   Magic   for  testing  on real  hardware.   
   Nosferatu,  Platon,  Dan,   Ok3anos  for   
   helpful tips.                              
   Noname, Hellfire, Artlace, and  possibly   
   others I forgot – you know who you are!    

