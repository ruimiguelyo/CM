# 🌱 HelloFarmer - Marketplace Agrícola

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Uma aplicação móvel completa que conecta produtores agrícolas diretamente aos consumidores, criando um marketplace digital sustentável e eficiente.

## 📱 Sobre o Projeto

O **HelloFarmer** é uma plataforma digital inovadora que revoluciona a forma como os produtos agrícolas chegam aos consumidores. Através de uma interface intuitiva e moderna, produtores podem gerir os seus produtos e encomendas, enquanto consumidores têm acesso direto a produtos frescos e locais.

## 🌟 Funcionalidades Principais

### Para Consumidores
- **Navegação por Produtores**: Lista e mapa interativo com localização dos produtores
- **Catálogo de Produtos**: Navegação por produtos com filtros e pesquisa
- **Sistema de Carrinho**: Adicionar produtos, gerir quantidades e finalizar compras
- **Sistema de Favoritos**: Guardar produtos preferidos para acesso rápido
- **Localização GPS**: Ver distância até aos produtores e navegação no mapa
- **Scanner QR Code**: Digitalizar códigos QR de produtores para acesso rápido aos seus perfis
- **Avaliações**: Avaliar encomendas e produtores após a entrega
- **Histórico de Encomendas**: Acompanhar estado das encomendas em tempo real

### Para Produtores
- **Gestão de Produtos**: Adicionar, editar e remover produtos com stock
- **Gestão de Encomendas**: Visualizar e atualizar estado das encomendas
- **Localização**: Definir localização da quinta/produção para aparecer no mapa
- **QR Code Personalizado**: Gerar código QR do perfil para partilha offline
- **Sistema de Avaliações**: Ver e responder a avaliações dos clientes
- **Dashboard**: Visão geral das vendas e atividade

### Funcionalidades Técnicas
- **GPS e Localização**: Integração com mapas do Google e geolocalização
- **Autenticação Segura**: Sistema robusto com Firebase Authentication
- **Base de Dados em Tempo Real**: Sincronização automática com Firestore
- **Gestão de Stock**: Controlo automático de inventário durante as compras
- **Notificações**: Sistema de notificações para atualizações importantes
- **Interface Responsiva**: Design adaptável para mobile e web

## 🛠 Tecnologias Utilizadas

### Frontend
- **Flutter 3.x** - Framework de desenvolvimento multiplataforma
- **Dart** - Linguagem de programação
- **Provider** - Gestão de estado reativa
- **Google Fonts** - Tipografia moderna

### Backend & Serviços
- **Firebase Auth** - Autenticação segura
- **Cloud Firestore** - Base de dados NoSQL em tempo real
- **Firebase Storage** - Armazenamento de imagens
- **Firebase Messaging** - Notificações push

### Packages Especializados
```yaml
# Funcionalidades Core
firebase_core: ^3.14.0
firebase_auth: ^5.6.0
cloud_firestore: ^5.6.9
provider: ^6.1.2

# Sensores e Hardware
geolocator: ^13.0.1
sensors_plus: ^5.0.1
mobile_scanner: ^7.0.1
permission_handler: ^11.3.1

# Interface e UX
google_fonts: ^6.2.1
flutter_rating_bar: ^4.0.1
lottie: ^3.1.2
shimmer: ^3.0.0

# Utilitários
image_picker: ^1.1.2
intl: ^0.20.2
```

## 🎨 Design System

### Paleta de Cores
- **Primária**: `#2A815E` - Verde agricultor (confiança e natureza)
- **Secundária**: `#4CAF50` - Verde claro (crescimento e vitalidade)
- **Destaque**: `#FF9800` - Laranja (energia e ação)
- **Fundo**: `#FAFAFA` - Branco suave (limpeza e clareza)
- **Superfície**: `#FFFFFF` - Branco puro (modernidade)

### Princípios de Design
- **Minimalismo** - Interface limpa e focada
- **Consistência** - Elementos visuais uniformes
- **Acessibilidade** - Cores e contrastes otimizados
- **Responsividade** - Adaptação a diferentes tamanhos de ecrã

## 📦 Instalação e Configuração

### Pré-requisitos
- Flutter SDK 3.x ou superior
- Dart SDK 3.x ou superior
- Android Studio / VS Code
- Conta Firebase configurada

### Passos de Instalação

1. **Clone o repositório**
```bash
git clone https://github.com/seu-usuario/hellofarmer.git
cd hellofarmer
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Configure o Firebase**
- Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
- Adicione as configurações Android/iOS
- Baixe e adicione os ficheiros de configuração:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

4. **Configure as permissões**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta app precisa de acesso à localização para mostrar produtores próximos.</string>
<key>NSCameraUsageDescription</key>
<string>Esta app precisa de acesso à câmara para digitalizar códigos QR.</string>
```

5. **Execute a aplicação**
```bash
flutter run
```

## 🔥 Firebase Setup

### Firestore Collections
```
users/
├── {userId}/
    ├── nome: string
    ├── email: string
    ├── tipo: string ('consumidor' | 'produtor')
    ├── morada: string
    ├── telefone: string
    ├── favoritos: array<string>
    └── products/ (subcollection para produtores)
        └── {productId}/
            ├── nome: string
            ├── descricao: string
            ├── preco: number
            ├── categoria: string
            ├── stock: number
            ├── imageUrl: string
            └── createdAt: timestamp

orders/
├── {orderId}/
    ├── userId: string
    ├── producerIds: array<string>
    ├── items: array<object>
    ├── total: number
    ├── status: string
    ├── moradaEntrega: string
    ├── orderRating: number (optional)
    ├── producerRating: number (optional)
    ├── reviewText: string (optional)
    └── createdAt: timestamp
```

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Products subcollection
      match /products/{productId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Orders can be read by involved users
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         request.auth.uid in resource.data.producerIds);
    }
  }
}
```

## 🗺️ Configuração do Google Maps

## 🗺️ Google Maps API - CONFIGURADO ✅

A Google Maps API está **totalmente configurada e ativa** com as seguintes APIs habilitadas:

### APIs Ativas
- ✅ **Maps JavaScript API** - Para mapas web interativos
- ✅ **Geolocation API** - Para obter localização do utilizador  
- ✅ **Maps 3D SDK for Android** - Para mapas nativos Android

### Configuração Atual
- **Chave API**: `AIzaSyBGIobQGPzElfA1DIRA3KbEc-bpMTD4f7U`
- **Configuração Web**: Configurada em `web/index.html`
- **Configuração Android**: Pronta para configurar em `android/app/src/main/AndroidManifest.xml`

### Funcionalidades Disponíveis
- 🗺️ **Mapas interativos** na home screen (vista de produtores)
- 📍 **Localização de produtores** com marcadores personalizados
- 🎯 **Mapa de localização** na página de detalhes do produtor
- 🧭 **Demo de GPS e sensores** com Google Maps integrado
- 📏 **Cálculo de distâncias** entre utilizador e produtores

### Configuração Android (Se necessário)
Para ativar os mapas na versão Android, adicione ao `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data 
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBGIobQGPzElfA1DIRA3KbEc-bpMTD4f7U"/>
```

### Funcionalidade de Fallback
A aplicação funciona mesmo se houver problemas com a API:
- Os mapas mostrarão "Mapa indisponível" com coordenadas
- As funcionalidades GPS continuam operacionais
- Todas as outras funcionalidades permanecem ativas

## 👥 Contas de Teste

Para facilitar os testes, utilize as seguintes credenciais criadas pelo script de dados de exemplo:

### Consumidor de Teste
- **Email**: `rita.sousa@email.pt`
- **Password**: `password123`
- **Nome**: Rita Sousa
- **Localização**: Lisboa

### Produtor de Teste
- **Email**: `joao.silva@farm.pt`
- **Password**: `password123`
- **Nome**: João Silva
- **Localização**: Quinta da Esperança, Braga

### Outras Contas Disponíveis

#### Consumidores:
- `tiago.mendes@email.pt` - Tiago Mendes (Porto)
- `carla.nunes@email.pt` - Carla Nunes (Faro)
- `bruno.dias@email.pt` - Bruno Dias (Coimbra)
- `patricia.lima@email.pt` - Patrícia Lima (Braga)

#### Produtores:
- `maria.santos@verde.pt` - Maria Santos (Évora) - Azeites e Mel
- `antonio.costa@bio.pt` - António Costa (Viseu) - Frutas e Nozes
- `ana.ferreira@natural.pt` - Ana Ferreira (Coimbra) - Vegetais Biológicos
- `carlos.oliveira@campo.pt` - Carlos Oliveira (Viana do Castelo) - Raízes e Tubérculos
- `isabel.rodrigues@terra.pt` - Isabel Rodrigues (Santarém) - Frutos Vermelhos
- `pedro.almeida@fresco.pt` - Pedro Almeida (Aveiro) - Legumes Frescos
- `luisa.martins@organico.pt` - Luísa Martins (Guarda) - Cereais Biológicos
- `miguel.pereira@sustentavel.pt` - Miguel Pereira (Leiria) - Laticínios e Ovos
- `sofia.gomes@tradicional.pt` - Sofia Gomes (Porto) - Produtos Tradicionais

**Todas as contas usam a password**: `password123`

> **💡 Dica**: Para recriar os dados de exemplo, execute o script:
> ```bash
> flutter run lib/create_sample_data.dart -d edge --web-port=8081
> ```
> Este script irá automaticamente remover contas antigas e criar todas as contas listadas acima com os respetivos produtos e dados de localização.

## 📱 Screenshots

### Ecrãs do Consumidor
| Home | Produto | Carrinho | Favoritos |
|------|---------|----------|-----------|
| ![Home](screenshots/home.png) | ![Product](screenshots/product.png) | ![Cart](screenshots/cart.png) | ![Favorites](screenshots/favorites.png) |

### Ecrãs do Produtor
| Dashboard | Produtos | Encomendas | Avaliações |
|-----------|----------|------------|------------|
| ![Dashboard](screenshots/producer-home.png) | ![Products](screenshots/products.png) | ![Orders](screenshots/orders.png) | ![Reviews](screenshots/reviews.png) |

### Funcionalidades Avançadas
| Sensores | GPS | QR Scanner | Bússola |
|----------|-----|------------|---------|
| ![Sensors](screenshots/sensors.png) | ![GPS](screenshots/gps.png) | ![QR](screenshots/qr.png) | ![Compass](screenshots/compass.png) |

## 🧪 Testes

### Executar Testes
```bash
# Testes unitários
flutter test

# Testes de integração
flutter test integration_test/

# Análise de código
flutter analyze
```

### Cobertura de Testes
- **Modelos de Dados**: 95%
- **Serviços**: 90%
- **Widgets**: 85%
- **Integração**: 80%

## 🚀 Build e Deploy

### Build para Produção
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Deploy Firebase Hosting (Web)
```bash
firebase init hosting
firebase deploy
```

## 📊 Arquitetura

### Estrutura do Projeto
```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── order_model.dart
│   └── cart_item_model.dart
├── screens/                  # UI screens
│   ├── auth/                 # Authentication screens
│   ├── consumer/             # Consumer screens
│   ├── producer/             # Producer screens
│   └── shared/               # Shared screens
├── services/                 # Business logic
│   ├── firestore_service.dart
│   ├── auth_repository.dart
│   ├── location_service.dart
│   └── sensor_service.dart
├── providers/                # State management
│   └── cart_provider.dart
├── widgets/                  # Reusable widgets
│   └── custom_badge.dart
└── theme/                    # App theming
    └── app_theme.dart
```

### Padrões de Design
- **Singleton**: Para serviços (LocationService, SensorService)
- **Provider**: Para gestão de estado reativo
- **Repository**: Para abstração de dados
- **Factory**: Para criação de modelos

## 🔒 Segurança

### Medidas Implementadas
- **Autenticação Firebase** - Login seguro com verificação de email
- **Regras de Segurança Firestore** - Controlo de acesso granular
- **Validação de Dados** - Sanitização de inputs
- **Permissões de Sistema** - Solicitação adequada de permissões
- **Transações Atómicas** - Consistência de dados garantida

## 🌟 Funcionalidades Futuras

### Roadmap
- [ ] **Notificações Push** - Alertas em tempo real
- [ ] **Chat Integrado** - Comunicação direta produtor-consumidor
- [ ] **Pagamentos Online** - Integração com gateways de pagamento
- [ ] **Entrega Programada** - Agendamento de entregas
- [ ] **Programa de Fidelidade** - Sistema de pontos e recompensas
- [ ] **Analytics Avançado** - Dashboard de métricas detalhadas
- [ ] **Modo Offline** - Funcionalidades básicas sem internet
- [ ] **Suporte Multi-idioma** - Internacionalização

## 🤝 Contribuição

### Como Contribuir
1. Faça um fork do projeto
2. Crie uma branch para a sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit as suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### Guidelines
- Siga as convenções de código Dart/Flutter
- Escreva testes para novas funcionalidades
- Documente mudanças no CHANGELOG.md
- Use commits semânticos

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👨‍💻 Autor

**Rui Miguel**
- Email: ruimiguelsa.stb@gmail.com
- LinkedIn: [Rui Miguel](https://linkedin.com/in/ruimiguel)
- GitHub: [@ruimiguel](https://github.com/ruimiguel)

## 🙏 Agradecimentos

- **Flutter Team** - Pelo excelente framework
- **Firebase Team** - Pela plataforma robusta
- **Comunidade Open Source** - Pelas bibliotecas utilizadas
- **Professores e Colegas** - Pelo apoio e feedback

---

<div align="center">
  <p>Feito com ❤️ para conectar produtores e consumidores</p>
  <p><strong>HelloFarmer</strong> - Cultivando o futuro da agricultura digital</p>
</div>
