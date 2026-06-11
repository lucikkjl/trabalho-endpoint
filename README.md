# Atividade Prática - Consumo de APIs REST

**Aluna:** Luciana  
**Curso:** Análise e Desenvolvimento de Sistemas (5ª Fase)  
**Instituição:** Faculdade Senac Joinville  

---

## 1. Mapeamento e Tratamento de Erros Implementados

No desenvolvimento deste aplicativo, que consome as plataformas ViaCEP e Dog API, foram implementadas camadas de segurança nos blocos try-catch para tratar os seguintes cenários:

* **SocketException:** Tratamento essencial para dispositivos móveis, pois indica a total ausência de rede (conexão com a internet). Evita que a aplicação tente estabelecer uma comunicação impossível.
* **TimeoutException:** Implementado com um limite rígido de 10 segundos. É crucial para impedir que o aplicativo fique em um estado de espera infinito caso o servidor da API esteja sobrecarregado ou a latência da rede do usuário esteja alta.
* **Códigos de Status HTTP Não-200:** * A validação de status HTTP, especificamente o erro **404 (Not Found)** na Dog API, previne que o código tente processar um JSON inexistente quando o usuário busca por uma raça de cachorro que não consta no banco de dados.

## 2. Feedback Visual e Interação com o Usuário

Para garantir uma interface responsiva, o usuário é informado sobre o status das requisições de duas maneiras:
* **Indicador de Processamento:** Durante o tráfego de rede, os botões têm suas funções desativadas e exibem um `CircularProgressIndicator`. Isso informa que a tarefa está em andamento e impede o acionamento repetido (spam de cliques).
* **Alertas de Erro:** Caso qualquer exceção seja capturada, o aplicativo exibe um `SnackBar` vermelho na base da tela contendo uma mensagem em linguagem natural e direta (ex: "Sem conexão de rede" ou "Raça não encontrada"), sem a necessidade de exibir códigos técnicos complexos.

## 3. Cenários Práticos de Ocorrência

Situações reais onde essas validações entram em ação:
* **SocketException:** O usuário abre o aplicativo para validar um endereço, mas o dispositivo encontra-se em "Modo Avião" ou em uma zona de sombra de sinal sem cobertura de operadora.
* **TimeoutException:** O usuário está conectado a uma rede Wi-Fi pública extremamente congestionada. O servidor da Dog API é alcançado, mas a transferência do arquivo de imagem leva muito tempo, disparando o bloqueio de 10 segundos.
* **Status HTTP 404:** O usuário comete um erro de digitação ao buscar a raça do cachorro (exemplo: digita "begle" em vez de "beagle"), ou tenta buscar usando termos regionais que a API internacional não suporta (como "vira-lata"). 

## 4. Comportamento do Sistema sem o Tratamento de Erros

A omissão dos blocos try-catch e do tratamento das exceções causaria falhas críticas no ciclo de vida do aplicativo:
* Um erro de `SocketException` não tratado se transformaria em uma exceção fatal, resultando em um *crash* do sistema (fechamento repentino do aplicativo). No ambiente de desenvolvimento, isso causaria a quebra da árvore de renderização.
* Se o código HTTP 404 passasse despercebido, a função `jsonDecode()` tentaria extrair dados de uma string vazia ou de um formato de erro nativo da API. A chamada `json['message']` dispararia um erro de objeto nulo (`NullPointerException`), travando a interface.
* Sem o bloco `finally` para reverter as variáveis booleanas de carregamento (`_isLoadingCep` e `_isLoadingDog`), qualquer erro deixaria o botão preso em estado de "carregando" para sempre, forçando o usuário a reiniciar o aplicativo manualmente.