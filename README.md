# kv_lc | key_value#2732
## Roubo de veiculos, com rastreador etc.
 O codigo foi feito em +/- 2 horas então provavelmente deve rolar alguns bugs, caso tenha, só criar um issue que eu dou uma olhada. Caso tenha alguma sugestão de alteração ou melhoria do script, sinta-se livre pra me contatar no discord

 
 
## Instalação
* Extraia a pasta `emp_lc` dentro da sua pasta resources. 
* adicione `start vrp_outlawalert` no seu `server.cfg`.
## Configurações
* Abra o arquivo `server.lua`. 
* Procure por `lc_permission = 'admin.permissao'`, mude para a permissao desejada. 
* em `lc_cooldown` você pode alterar a quantidade em segundos do cooldown entre roubos
* em `lc_scramble` é o tempo em segundos para embaralhar quais veiculos poderão ser roubados e em quais lugares
* em `vehicles` você pode alterar quais veiculos você quer que possam ser roubados.
* `model` é o modelo para spawnar o veiculo.
* `name` é o nome de display do veiculo.
* `reward` é o tanto de dinheiro ganho ao vender o veiculo.