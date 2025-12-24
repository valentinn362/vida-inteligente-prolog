%integrador de logica
:- use_module(library(csv)).
:- dynamic planeta/2.

% carga el archivo csv con los datos de planetas
% lee cada fila y la convierte en un hecho planeta(nombre, condicion)
cargar_planetas :-
    csv_read_file('./planetas.csv', [Header|Filas], [functor(planeta)]),
    retractall(planeta(_,_)),
    maplist(assert, Filas),
    writeln('Planetas cargados.'), writeln(Header), imprimir_lista(Filas).

% imprime recursivamente cada elemento de una lista
imprimir_lista([]).
imprimir_lista([Cabeza|Cola]) :-
    writeln(Cabeza),
    imprimir_lista(Cola).

% muestra el menu principal y lee la opcion del usuario
inicio :-
    writeln('opciones:'),
    writeln('1-cargar hechos'),
    writeln('2-imprimir hechos cargados'),
    writeln('3-inferir'),
    writeln('4-demostrar'),
    writeln('5-ver condiciones'),
    writeln('6-salir'),
    write('seleccione una opcion del 1 al 6: '),
    read(Opcion),
    nl,
    ejecutar(Opcion).


%predicados para ejecutar el menu

% opcion 1: Cargar
ejecutar(1):-
    cargar_planetas,
    inicio.

% opcion 2: imprimir
ejecutar(2):-
    imprimir_hechos_cargados,
    inicio.

% opcion 3: inferir
ejecutar(3) :-
    writeln('--- Consulta de Inferencia ---'),
    writeln('Puede usar un atomo (ej: habitable) o una Variable (ej: C o P).'),
    write('Ingrese Condicion: '),
    read(Condicion),
    write('Ingrese Planeta: '),
    read(Planeta),

    findall(inferir(Condicion, Planeta),
            inferir(Condicion, Planeta),
            Soluciones),

    % Llamamos al impresor corregido
    imprimir_soluciones(Soluciones),
    nl,
    inicio.

% opcion 4: explicar/demostrar
ejecutar(4):-
    writeln('se le pedira la Condicion y el Planeta.'),
    write('ingrese Condicion: '),
    read(Condicion),
    write('ingrese Planeta: '),
    read(Planeta),
    demostrar(Condicion, Planeta),
    nl,
    inicio.

% opcion 5: mostrar condiciones
ejecutar(5):-
    write('ingrese el nombre de la regla (ej: vida_compleja): '),
    read(Regla),
    findall(Lista,
            condiciones(Regla, Lista),
            Soluciones),
    imprimir_soluciones(Soluciones),
    nl,
    inicio.

% opcion 6: salir
ejecutar(6):-
    writeln('saliendo del sistema').


% esta regla solo se ejecuta si las del 1 al 6 fallan
ejecutar(_) :-
    writeln('opcion no valida, intente de nuevo.'),
    inicio.

% recorre todos los hechos planeta en memoria y los imprime
imprimir_hechos_cargados :-
    writeln('hechos base cargados'),
    forall(planeta(P, H), writeln(planeta(P, H))).



% maneja el caso donde no se encontraron soluciones
imprimir_soluciones([]):-
    writeln('FALSE:no se encontraron resultados').

% imprime la lista de soluciones encontradas
imprimir_soluciones(ListaSoluciones) :-
    ListaSoluciones \= [],
    writeln('resultados encontrados:'),
    maplist(writeln, ListaSoluciones).


% base de conocimiento: define las reglas del sistema experto
% cada regla tiene una lista de requisitos que deben cumplirse

% vida basica requiere condiciones minimas para organismos simples
condiciones(vida_basica, [tiene_atmosfera, tiene_agua_liquida, tiene_elementos_biogenicos]).

% vida compleja necesita evolucion desde formas basicas
condiciones(vida_compleja, [vida_basica, tiene_evolucion_biologica, tiene_superficie_solida]).

% vida inteligente requiere capacidad tecnologica
condiciones(vida_inteligente, [vida_compleja, tiene_tecnologia]).

% habitable significa que puede sostener vida de forma estable
condiciones(habitable, [tiene_atmosfera, tiene_magnetosfera, tiene_gravedad_estable, tiene_ciclo_dia_noche]).

% fotosintesis necesita luz y atmosfera para procesos biologicos
condiciones(fotosintesis_posible, [tiene_luz_solar, tiene_atmosfera]).

% civilizacion avanzada combina todos los factores anteriores
condiciones(civilizacion_avanzada, [vida_inteligente, habitable, fotosintesis_posible]).


% motor de inferencia: verifica si un planeta cumple una condicion

% caso base: busca directamente en los hechos cargados
inferir(Condicion, Planeta) :-
    planeta(Planeta, Condicion).

% caso recursivo: si la condicion es una regla, verifica todos sus requisitos
% usa maplist para aplicar inferir_condicion a cada requisito de la lista
inferir(Condicion, Planeta) :-
    condiciones(Condicion, ListaCondiciones),
    maplist(inferir_condicion(Planeta), ListaCondiciones).

% verifica un requisito individual para un planeta dado
% auxiliar para llamar a inferir con el planeta fijo
inferir_condicion(Planeta, Condiciones) :-
    inferir(Condiciones, Planeta).

% inicia el proceso de demostracion explicativa
% usa findall para encontrar todas las posibles demostraciones
demostrar(Condicion, Planeta) :-
    writeln('iniciando demostracion'),
    findall(E,
            por_que(Condicion, Planeta, 0, E),
            Soluciones),
    imprimir_demostracion(Soluciones).

% indica si la demostracion tuvo exito o fallo
imprimir_demostracion([]) :-
    writeln('demostracion fallida').
imprimir_demostracion([_|_]) :-
    writeln('demostracion exitosa').

% caso donde la condicion es una regla compuesta
% imprime la regla e itera sobre sus requisitos con mayor nivel de sangria
por_que(Regla, Planeta, Nivel, ListaCondiciones) :-
    condiciones(Regla, ListaCondiciones),
    imprimir_sangria(Nivel),
    write('Inferido: '), writeln(Regla),
    SiguienteNivel is Nivel + 1,
    maplist(por_que_condicion(Planeta, SiguienteNivel), ListaCondiciones).

% caso base: la condicion es un hecho directo del csv
% imprime el hecho con sangria segun el nivel de profundidad
por_que(Hecho, Planeta, Nivel, es_un_hecho_base) :-
    planeta(Planeta, Hecho),
    imprimir_sangria(Nivel),
    write('Hecho Base: '), writeln(Hecho).

% auxiliar para verificar cada requisito en la demostracion
% mantiene el planeta y nivel para la recursion
por_que_condicion(Planeta, Nivel, Condicion) :-
    por_que(Condicion, Planeta, Nivel, _).


% imprime espacios para crear la sangria del arbol de inferencia
% caso base: nivel 0 no imprime nada
imprimir_sangria(0) :- !.
% caso recursivo: imprime 4 espacios y decrementa el nivel
imprimir_sangria(Nivel) :-
    write('    '),
    NivelSiguiente is Nivel - 1,
    imprimir_sangria(NivelSiguiente).

