# TicketPlus

O TicketPlus é uma aplicação Flutter desenvolvida para localizar e gerir estabelecimentos que aceitam vales de refeição/alimentação. O projeto utiliza integração com Google Maps para visualização espacial e SQLite para persistência de dados local.

## Funcionalidades

* Mapa Interativo: Visualização de estabelecimentos próximos usando a API do Google Maps.
* Marcadores Personalizados: Exibição de pontos de interesse no mapa.
* Persistência Local: CRUD (Criar, Ler, Atualizar, Apagar) completo usando SQLite.
* Geolocalização: Detecção da posição atual do utilizador.
* Gestão de Dados: Cadastro de estabelecimentos com Nome, Categoria e Bandeira (Ticket, Alelo, etc.).

## Tecnologias Utilizadas

* Flutter (SDK >=3.2.3)
* Google Maps Flutter
* Sqflite (Banco de dados local)
* Geolocator

## Como Rodar o Projeto

### 1. Pré-requisitos

Certifique-se de ter instalado:
* Flutter SDK
* Android Studio (com Android SDK 34 configurado)
* Uma API Key válida do Google Maps Platform

### 2. Clonar o Repositório

```bash
git clone https://github.com/SEU_USUARIO/ticketplus.git
cd ticketplus
```

### 3. Instalar Dependências

```bash
flutter pub get
```

### 4. Configuração da API Key

Para que o mapa carregue, você precisa adicionar sua Chave de API do Google.

1. Abra o arquivo: `android/app/src/main/AndroidManifest.xml`
2. Procure a tag `<meta-data>` dentro de `<application>`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="SUA_CHAVE_API_AQUI"/>
```

3. Substitua `SUA_CHAVE_API_AQUI` pela sua credencial real do Google Cloud Console

### 5. Rodar a Aplicação

Conecte seu dispositivo ou inicie um emulador Android e execute:

```bash
flutter run
```

## Solução de Problemas

### O botão de localização não funciona

Se estiver a usar um Emulador Android, a permissão de GPS nem sempre é solicitada automaticamente.

1. Vá nas Configurações do emulador
2. Acesse Apps > TicketPlus > Permissões
3. Ative manualmente a permissão de Localização
4. Reinicie a app