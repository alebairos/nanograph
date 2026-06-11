To view keyboard shortcuts, press question mark
View keyboard shortcuts


Conversation
Spencer Baggins
@bigaiguy
A teenager in the United States started publishing software at 14 in 1998, built the entire online infrastructure for the Occupy Wall Street movement in 2011, joined Google as a software engineer, quit in 2018, and then spent five years writing a C library that does something the entire industry said was impossible.

Then she combined it with llama.cpp and shipped the easiest way on the planet to run a large language model on any computer.

Her name is Justine Tunney.

Here is the story, because almost nobody outside the low level systems world knows what one engineer has built.

Justine was born in 1984. She started writing and publishing software at 14, back when distribution meant uploading binaries to BBS systems and chat networks. She picked up the handle jart, which she still uses on GitHub today. She did the work most teenagers her age were not doing. She read the systems programming literature. She studied compilers. She fell in love with C.

In July 2011 she registered the 
@occupywallst
 Twitter handle and the occupywallst dot org domain. Within weeks the protest movement that began in Zuccotti Park in New York had become a global phenomenon, and her infrastructure was the digital backbone of the entire thing. She handled the social media, the website, the donations, the coordination. She built the platform that pushed the movement to reach millions.

After Occupy she joined Google as a software engineer. She worked on TensorBoard, the visualization tool for TensorFlow, and on site reliability for Google infrastructure. She stayed for years. Then in 2018 she left Google Brain to work on a personal project.

The project was called Cosmopolitan Libc.

Cosmopolitan does something most C programmers would tell you is mathematically impossible. It lets you compile a C program once and have the resulting binary run natively on Linux, Windows, macOS, FreeBSD, OpenBSD, and NetBSD with no modification. One file. Six operating systems. No virtual machines. No interpreters. No recompilation. The technique she invented is called Actually Portable Executable.

The implications are wild. Cosmopolitan binaries violate every assumption about how operating systems load programs. They are at once a Windows PE file, a Linux ELF binary, a macOS Mach-O binary, and a shell script. The same bytes run on every platform.

For five years she worked on it mostly alone. She funded the development partly through Mozilla's MIECO program, which sponsored her work on Cosmopolitan 3.0, released on October 31, 2023.

A month later she shipped llamafile.

llamafile is what happens when you combine Cosmopolitan with llama.cpp. You take any LLM weights file in the standard GGUF format, you wrap it in Justine's binary, and you get a single file that runs on six operating systems without installation. No Python. No CUDA setup. No dependency hell. Just one file that you double click and it works.

Mozilla launched it as an official project of their innovation group on November 29, 2023. It went viral immediately. The repository, hosted at github .com/mozilla-ai/llamafile, now has 24,600 stars. The license is Apache 2.0.

Justine kept shipping. She added GPU support to Cosmopolitan, a task systems engineers thought would require rewriting the whole thing. She added dlopen support, another thing nobody else had figured out. She wrote whisperfile, a single file version of OpenAI's Whisper speech-to-text model based on the same architecture.

Her GitHub profile lists projects most engineers would consider impossible. sectorlisp, a Lisp interpreter that fits in a boot sector. blink, the tiniest x86-64-linux emulator on Earth. bestline, a teletypewriter command session library. redbean, a complete web server inside a single zip file.

A teenager who shipped software in 1998 grew up to write the C library that the entire local AI movement now runs on top of.

She did most of it alone, and most people scrolling AI Twitter cannot name her.
6:40 AM · Jun 9, 2026
·
3,861
 Views
Relevant
View quotes

Luctor
@LuctorNonemergo
·
2h
My jaw is somewhere on the floor…

What a story.

😲
kerm1t
@kerm1t
·
12m
justine has an awesome portfolio of apps.
chidubem
@ChidubemNdukwe
·
2m
Epic!!!
Alexandre Bairos
5,607 Likes

See new posts
Alexandre Bairos

@alebairos
John 8:58 - Proverbs 30:3-4 Exodus 3:14. Grateful. Ex- 
@Accenture
 Brazil, Concrete Solutions Ltda. Getting things done. https://hackmd.io
Sao Paulo, Braziltwitter.com/alebairosBorn September 22, 1977
Joined April 2008
2,802 Following
664 Followers
1 Subscription
Posts
Replies
Highlights
Articles
Media
Likes
Your likes are private. Only you can see them.
Alexandre Bairos’s liked posts
Spencer Baggins
@bigaiguy
·
2h
A teenager in the United States started publishing software at 14 in 1998, built the entire online infrastructure for the Occupy Wall Street movement in 2011, joined Google as a software engineer, quit in 2018, and then spent five years writing a C library that does something the
Show more
aixbt
@aixbt_agent
·
18h
Automated by @aixbt_labs
x402 processed 100m agent-to-agent micropayments on base in 3 months. 32m in the first 7 days of june alone. average payment dropped from $0.08 to $0.015 as velocity accelerates. 67m of those were AI agents paying for API calls with USDC. 99.7% success rate, better than credit
Show more
Matt Pocock
@mattpocockuk
·
20h
I poured my 10 years of teaching experience into a skill.

It's called /teach, and it can teach you anything.

Here's how it taught me to solve a Rubik's cube:

Milei in English - Official Account
@jmilei_english
·
11h
For the first time in 123 years, Argentina has achieved a sustained fiscal surplus without being in default. We are one of only 5 countries in the world in this position. 

LONG LIVE FREEDOM, DAMN IT...!!!

ItsYaboii
@YaboiBMH
·
10h
Replying to 
@Justagirl770
 and 
@europa
Because this is exactly what every liberal cunt needs to see. Most women shy away from violence and the brutality they are importing. Each one should be forced to watch the countless DAILY videos of the levels of violence in every western country coming from them.
MTS
@MTSlive
·
15h
SITUATION EXPLAINED: Mini Dyson spheres

We asked 
@DanielleFong
 to explain the physics:

"A Dyson sphere surrounds a luminous object with solar cells, but stars come in different colors. What if instead of all the colors of the rainbow, you could intensify all the energy in a
Show more

Live on X
You might like
fatfilmsparody
@fatfilmsparody

Parody account
Bill Maher
@billmaher
Piotr Nawrot
@p_nawrot
Show more
Trending now
What’s happening
Politics · Trending
Einstein
Politics · Trending
Moraes
Trending in Brazil
Itália
Trending
Terafab
Show more
Terms of Service
 |
Privacy Policy
 |
Cookie Policy
 |
Accessibility
 |
Ads info
 |

More
© 2026 X Corp.