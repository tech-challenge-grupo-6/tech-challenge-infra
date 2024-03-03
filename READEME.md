# Guia de Configuração do Terraform com AWS CLI

Este guia descreve os passos necessários para configurar o Terraform e a AWS CLI, permitindo que você execute comandos Terraform no arquivo `main.tf` para provisionar recursos na AWS.

## Pré-requisitos

Antes de começar, certifique-se de ter o seguinte instalado em sua máquina:

- [Terraform](https://www.terraform.io/downloads.html)
- [AWS CLI](https://aws.amazon.com/cli/)

## Configuração da AWS CLI

Siga os passos abaixo para configurar a AWS CLI:

1. Abra o terminal e execute o comando `aws configure`.
2. Serão solicitadas as seguintes informações:
    - **AWS Access Key ID**: Insira sua chave de acesso da AWS.
    - **AWS Secret Access Key**: Insira sua chave secreta de acesso da AWS.
    - **Default region name**: Insira a região padrão que você deseja usar (por exemplo, `us-east-1`).
    - **Default output format**: Deixe em branco para usar o formato de saída padrão.

Após inserir essas informações, a configuração da AWS CLI estará concluída.

## Executando comandos Terraform

Agora que você configurou a AWS CLI, você pode executar comandos Terraform no arquivo `main.tf` para provisionar recursos na AWS. Siga os passos abaixo:

1. Abra o terminal e navegue até o diretório onde está localizado o arquivo `main.tf`.
2. Execute o comando `terraform init` para inicializar o diretório do Terraform.
3. Execute o comando `terraform plan` para visualizar as alterações que serão feitas na infraestrutura.
4. Execute o comando `terraform apply` para aplicar as alterações e provisionar os recursos na AWS.

Lembre-se de revisar e ajustar o arquivo `main.tf` de acordo com suas necessidades antes de executar os comandos Terraform.

## Conclusão

Agora você está pronto para executar comandos Terraform no arquivo `main.tf` e provisionar recursos na AWS. Certifique-se de revisar a documentação oficial do Terraform e da AWS CLI para obter mais informações sobre como usar essas ferramentas.

**Observação**: Este guia assume que você já possui uma conta na AWS e está familiarizado com os conceitos básicos do Terraform e da AWS CLI. Se você é novo nessas ferramentas, recomendamos que você consulte a documentação oficial para obter mais informações.