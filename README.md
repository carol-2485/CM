# BloodLink 🩸

*Plataforma móvel de gestão de doações de sangue*

Desenvolvida em Flutter com Firebase como backend.

---

## 1. Visão Geral

O **BloodLink** é uma aplicação Flutter que conecta doadores de sangue com centros de saúde, simplificando o processo de agendamento de doações. A aplicação tem dois perfis distintos de utilizador — doador e centro de saúde — cada um com o seu próprio painel e fluxo de trabalho.

---

## 2. Pré-requisitos

Certifique-se de ter instalado:

| Ferramenta | Verificação / Notas |
|---|---|
| Flutter SDK ≥ 3.19.0 | `flutter --version` |
| Dart SDK ≥ 3.3.0 | `dart --version` (incluído no Flutter) |
| Node.js ≥ 18.x | `node --version` (para Firebase CLI) |
| Firebase CLI | `firebase --version` |
| Chrome (para web) | qualquer versão recente |
| Android Studio / Xcode | para compilação móvel (opcional) |

---

## 3. Instalação

### 3.1 Clonar o repositório

```bash
git clone https://github.com/utilizador/bloodlink.git
cd bloodlink
```

### 3.2 Instalar as dependências Flutter

```bash
flutter pub get
```

### 3.3 Verificar o ambiente

```bash
flutter doctor
```

Todos os itens relevantes devem estar com ✓. Podem existir avisos para plataformas que não planeia usar (ex: iOS se não tiver Xcode).

---

## 4. Configuração

### 4.1 Firebase

O projecto usa Firebase para autenticação, base de dados e notificações. É necessário configurar um projecto Firebase próprio:

1. Aceda a [console.firebase.google.com](https://console.firebase.google.com) e crie um projecto.
2. Active os seguintes serviços: **Authentication** (Email/Password) e **Cloud Firestore** (modo de produção).
3. Crie uma aplicação Web no projecto Firebase e copie as credenciais.

### 4.2 Ficheiro `.env`

Crie um ficheiro `.env` na raiz do projecto (ao lado de `pubspec.yaml`) com o seguinte conteúdo:

```env
# Firebase
FIREBASE_API_KEY=AIza...
FIREBASE_AUTH_DOMAIN=o-seu-projeto.firebaseapp.com
FIREBASE_PROJECT_ID=o-seu-projeto
FIREBASE_STORAGE_BUCKET=o-seu-projeto.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=1:123456789:web:abc123
FIREBASE_MEASUREMENT_ID=G-XXXXXXXX

# Google Gemini AI (para o chat com IA)
GEMINI_API_KEY=AIza...
```

> **Nota de segurança:** O ficheiro `.env` está incluído no `.gitignore` e **nunca deve ser submetido ao repositório**.

### 4.3 Regras do Firestore

No painel do Firebase, em Firestore → Regras, configure:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 5. Execução

### Web (Chrome) — desenvolvimento

```bash
flutter run -d chrome
```

### Web com porta específica

```bash
flutter run -d chrome --web-port 3000
```

### Android (emulador ou dispositivo físico)

```bash
# Listar dispositivos disponíveis
flutter devices

# Executar no dispositivo seleccionado
flutter run -d <id-do-dispositivo>
```

### Build para produção (web)

```bash
flutter build web --release
```

Os ficheiros gerados ficam em `build/web/` e podem ser alojados em qualquer servidor estático ou no Firebase Hosting.

### Firebase Hosting (opcional)

```bash
firebase login
firebase init hosting
flutter build web --release
firebase deploy
```

---

## 6. Funcionalidades

### Sessão do Utilizador (Doador)

| Funcionalidade | Descrição |
|---|---|
| Autenticação | Registo, login e recuperação de palavra-passe |
| Avaliação de aptidão | Questionário clínico com verificação via OpenFDA API |
| Agendamento | Fluxo em 3 passos: centro → horário → confirmação |
| Geração automática de vagas | O sistema cria vagas respeitando o horário do centro |
| Painel do doador | Estatísticas: doações, sangue doado, vidas salvas |
| Histórico de doações | Registo automático após a hora da consulta passar |
| Notificações | Confirmações de agendamento e mensagens em tempo real |
| Chat com centro | Mensagens directas para o centro de saúde |
| Chat com IA | Assistente Gemini especializado em doação de sangue |
| Apoio | Chamada WhatsApp, chat IA ou mensagem para centro |

### Sessão do Centro de Saúde

| Funcionalidade | Descrição |
|---|---|
| Autenticação | Login com conta de centro (detectada automaticamente) |
| Gestão de vagas | Toggle disponível/indisponível por dia e horário |
| Pedidos de agendamento | Aceitar ou recusar pedidos dos doadores |
| Notificação automática | O doador é notificado da confirmação/recusa |
| Chat com doadores | Lista com badge de não lidas e ordenação por recente |
| Perfil do centro | Informações + horário de funcionamento semanal |

---

## 7. Tecnologias Utilizadas

| Tecnologia | Utilização |
|---|---|
| **Flutter 3.x** | Framework de UI multiplataforma |
| **Firebase Auth** | Autenticação de utilizadores |
| **Cloud Firestore** | Base de dados NoSQL em tempo real |
| **Google Gemini AI** | Assistente de chat com IA |
| **OpenFDA API** | Verificação de medicamentos no questionário |
| **flutter_map + OpenStreetMap** | Mapa interactivo de centros |
| **Geolocator** | Localização GPS para ordenar centros por proximidade |
| **url_launcher** | Abertura de WhatsApp para apoio |
| **flutter_dotenv** | Gestão segura de variáveis de ambiente |
| **intl** | Formatação de datas em português de Portugal |

---

## 8. Notas de Desenvolvimento

- A paleta de cores (`AppColors`) está centralizada em `constants/app_colors.dart`
- Todas as rotas nomeadas estão em `constants/app_routes.dart`
- Os serviços nunca acedem directamente à UI — apenas devolvem dados ou lançam excepções
- O `DoacoesService.sincronizarDoacoesConcluidas()` é chamado ao iniciar a Página Inicial e o Painel para actualizar automaticamente o histórico
- As notificações de mensagens são agrupadas por chat — múltiplas mensagens não lidas geram um único cartão com badge contador
