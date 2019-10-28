###### emp_lc | key_value#2732
# Roubo de veiculos, com rastreador etc.
 Script totalmente refeito. Deve haver menos bug e possiveis exploits por conta da maioria das coisas serem verificadas pelo servidor. Qualquer duvida ou sugestão, crie um issue ou me mande mensagem no discord `key_value#2732`

  
# Instalação
* Extraia a pasta `emp_lc` dentro da sua pasta resources. 
* Adicione `start emp_lc` no seu `server.cfg`.
# Configurações
* Abra o arquivo `server.lua`. 
* Procure por: `-- CONFIG`
  * `cPermission` para alterar a permissão ('' = sem permissão). 
  * `cCopPermission` para alterar a permissão da policia.
  * `cCops` para alterar o número mínimo de policiais.
  * `cGlobalRadar` para mostrar ou não o rastreador à todos.
  * `cSeconds` para alterar o tempo do rastreador.
  * `cCooldownSeconds` para alterar o tempo de cooldown após o termino.
  * `cRandomizeSeconds` para alterar o tempo em que são alterados os veículos.
  * `cVehicles` para alterar os veículos. Formato: `[id] = {'modelo', 'nome', recompensa}`