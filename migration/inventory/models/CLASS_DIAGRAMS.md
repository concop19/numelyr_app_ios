# Class diagrams cho model Swift đích

Tài liệu này mô tả model đích trong `numelyra_app_ios/Shared/Models` sau khi đối chiếu source React Native tại ref `b89d94fdbee6118edca8c09d9232115da081afb9`. Có đúng **10 Mermaid class diagram**: 1 overview và 9 sơ đồ domain/boundary. Dấu `?` biểu thị optional; quan hệ có nhãn `inferred` được giải thích ngay dưới sơ đồ.

## 0. Tổng quan kiến trúc dữ liệu

```mermaid
classDiagram
    direction LR
    class ProfileDomain
    class ChatReadingDomain
    class CalendarDomain
    class AstrologyDomain
    class WallpaperDomain
    class SettingsBillingDomain
    class GameHubDomain
    class MiniGameDomain
    class BoundaryLayer

    ProfileDomain --> ChatReadingDomain : supplies identity
    ProfileDomain --> AstrologyDomain : supplies birth data
    ProfileDomain --> WallpaperDomain : supplies personalization
    CalendarDomain --> AstrologyDomain : supplies daily ca dao
    SettingsBillingDomain --> GameHubDomain : schedules daily deep link
    GameHubDomain *-- MiniGameDomain : launches
    BoundaryLayer ..> ProfileDomain : maps cloud and local data
    BoundaryLayer ..> ChatReadingDomain : maps API DTOs
    BoundaryLayer ..> AstrologyDomain : maps API DTOs
    BoundaryLayer ..> WallpaperDomain : maps API DTOs
```

Các cạnh trong overview là dependency giữa domain, không phải cardinality của record. Evidence: `App.tsx:80-101`, `ChatScreen.tsx:1010-1185`, `astroFortuneService.ts:76-150`, `GameHubScreen.tsx:45-130`.

## 1. App shell, authentication và profile

```mermaid
classDiagram
    direction LR
    class Gender {
        <<enumeration>>
        male
        female
    }
    class UserProfile {
        +String id
        +String fullName
        +String birthDate
        +Gender? gender
        +Bool isDefault
        +String? birthTime
        +String? birthPlace
    }
    class AccountProfileDTO {
        +String id
        +String? email
        +String? fullName
        +String updatedAt
    }
    class CloudNumerologyProfileDTO {
        +String id
        +String userId
        +String name
        +String birthDate
        +String? createdAt
    }
    class AuthSession {
        +String accessToken
        +String refreshToken
        +String userId
        +String? userEmail
        +Date? expiresAt
    }

    UserProfile --> Gender : uses
    AuthSession "1" --> "0..1" AccountProfileDTO : identifies account
    AuthSession "1" --> "0..*" CloudNumerologyProfileDTO : owns remotely
    CloudNumerologyProfileDTO "0..*" ..> "0..*" UserProfile : maps by id or normalized identity (inferred)
```

Quan hệ inferred phản ánh merge cloud/local trong `src/store/authContext.tsx:38-124`. Cloud row không có `gender`, `birthTime`, `birthPlace` hoặc `isDefault`; mapper phải áp dụng policy rõ ràng thay vì coi hai schema là cùng một model. Swift: `UserProfile.swift`, `BoundaryModels.swift`.

## 2. Numerology, Tarot và Chat

```mermaid
classDiagram
    direction TB
    class ChatMessage {
        +String id
        +MessageSender sender
        +String text
        +String time
        +ChatCardPayload? card
        +Bool isTypingCompleted
    }
    class ChatCardPayload {
        <<enumeration>>
        agentSynthesis
        unsupported
    }
    class AgentSynthesisPayload {
        +AgentDecision decision
        +UserProfile[] profiles
        +DrawnTarotCard[] drawnCards
        +NumerologyIndicator[]? indicators1
        +NumerologyIndicator[]? indicators2
        +TuViBaziSynastry? tuViBazi
        +ColorGuidanceContext? colorGuidance
    }
    class AgentDecision {
        +AgentMode mode
        +AgentIntent intent
        +Bool needsTarot
        +TarotSpreadID? spreadId
        +Int cardCount
        +String[] targetIndicators
    }
    class TarotSpread {
        +TarotSpreadID id
        +String nameVi
        +TarotPosition[] positions
    }
    class TarotPosition {
        +String id
        +String nameVi
        +String descVi
    }
    class TarotCard {
        +String id
        +String nameVi
        +String nameEn
        +String[] keywordsUpright
        +String[] keywordsReversed
    }
    class DrawnTarotCard {
        +TarotCard card
        +Bool isReversed
        +TarotPosition position
    }
    class NumerologyCardDefinition {
        +String id
        +String key
        +IndicatorCategory category
        +String assetName
    }
    class NumerologyIndicator {
        +String key
        +String name
        +NumerologyValue value
        +String meaning
    }
    class CalculatedNumerologyIndicator {
        +NumerologyCardDefinition definition
        +NumerologyValue value
        +String displayValue
        +Bool isMaster
    }
    class TuViBaziSynastry
    class ColorGuidanceContext

    ChatMessage "1" o-- "0..1" ChatCardPayload : stores
    ChatCardPayload "1" o-- "0..1" AgentSynthesisPayload : typed case
    AgentSynthesisPayload "1" *-- "1" AgentDecision : decision
    AgentSynthesisPayload "1" o-- "0..*" DrawnTarotCard : reading
    AgentSynthesisPayload "1" o-- "0..*" NumerologyIndicator : chat values
    AgentSynthesisPayload "1" o-- "0..1" TuViBaziSynastry : compatibility
    AgentSynthesisPayload "1" o-- "0..1" ColorGuidanceContext : color result
    AgentDecision ..> TarotSpread : selects by spreadId
    TarotSpread "1" *-- "1..5" TarotPosition : defines
    DrawnTarotCard "1" --> "1" TarotCard : references
    DrawnTarotCard "1" --> "1" TarotPosition : occupies
    CalculatedNumerologyIndicator "1" *-- "1" NumerologyCardDefinition : presents
```

`IndicatorInfo` và `CalculatedIndicator` được giữ thành hai model Swift riêng, thay vì trộn field của hai schema. Evidence: `numerology24Service.ts:52-57`, `numerologyEngine.ts:85-89`, `ChatScreen.tsx:813-849`. Swift: `Numerology.swift`, `Tarot.swift`, `AgentDecision.swift`, `ChatMessage.swift`.

## 3. Calendar và dữ liệu văn hóa

```mermaid
classDiagram
    direction LR
    class CalendarWeekInfo {
        +Int weekNumber
        +CalendarDayItem[] days
    }
    class CalendarDayItem {
        +Date date
        +Int dayNumber
        +String dayOfWeekVi
        +String dayOfWeekShort
        +Bool isCurrentDay
    }
    class LunarDate {
        +Int day
        +Int month
        +Int year
        +Bool leap
    }
    class LunarHourInfo {
        +String name
        +String range
        +Int startHour
        +Bool isHoangDao
        +Bool isClash
        +String label
    }
    class DayHoangDaoStatus {
        +Bool isHoangDao
        +String label
    }
    class CaDaoRecord {
        +Int id
        +String title
        +String content
        +String category
        +String url
    }

    CalendarWeekInfo "1" *-- "7" CalendarDayItem : contains
    CalendarDayItem "1" ..> "1" LunarDate : converts to
    CalendarDayItem "1" ..> "12" LunarHourInfo : calculates
    CalendarDayItem "1" ..> "1" DayHoangDaoStatus : evaluates
    CalendarDayItem "1" ..> "0..1" CaDaoRecord : daily lookup (inferred)
```

Quan hệ ca dao là inferred từ ngày được truyền vào `getDailyCaDao`. Thuật toán parity bắt buộc là `seed = day * 31 + month * 37 + year * 7`, sau đó `ORDER BY id LIMIT 1 OFFSET seed % total` (`src/db/cadaoService.ts:94-120`). Swift: `LunarCalendar.swift`.

## 4. Astrology

```mermaid
classDiagram
    direction TB
    class AstroPlanetaryChart {
        +Date targetDate
        +Bool isTimeEstimated
        +AstroPlanetPosition[String] planets
        +AstroPlanetPosition[] planetList
    }
    class AstroPlanetPosition {
        +String name
        +Double longitude
        +String sign
        +Int signIndex
        +Double degreeInSign
        +Double normalized
    }
    class AstroAspectDefinition {
        +AstroAspectType type
        +Double targetAngle
        +Double maxOrb
        +AstroAspectNature nature
        +Double baseWeight
    }
    class DetectedAstroAspect {
        +String transitPlanet
        +String natalPlanet
        +AstroAspectType type
        +Double actualAngle
        +Double orb
        +Double weight
        +AstroAspectNature nature
    }
    class AstroAspectAnalysis {
        +DetectedAstroAspect[] aspects
        +DetectedAstroAspect? topAspect
        +Double tensionScore
        +Double harmonyScore
        +Double conjunctionIntensity
        +Double fastPlanetActivity
    }
    class TemperamentBalance {
        +Double fire
        +Double earth
        +Double air
        +Double water
        +Double cardinal
        +Double fixed
        +Double mutable
    }
    class AstroFeatureMetadata {
        +String birthDate
        +String? birthTime
        +Bool hasExactTime
        +Double confidenceScore
        +AstroTemperamentMetadata temperament
        +DetectedAstroAspect? topAspect
        +AstroScoreMetadata scores
        +AstroDominantSignal dominantSignal
    }
    class AstroVectorResult {
        +Double[] vector
        +AstroFeatureMetadata metadata
    }
    class AstroFortuneSlip {
        +String? title
        +String verse
        +String mirror
        +String advice
        +AnchorCaDao anchorCaDao
        +AstroFeatureMetadata? astroMetadata
    }
    class AnchorCaDao {
        +String content
        +String? category
    }

    AstroPlanetaryChart "1" *-- "10" AstroPlanetPosition : planets
    AstroAspectAnalysis "1" *-- "0..*" DetectedAstroAspect : results
    DetectedAstroAspect ..> AstroAspectDefinition : evaluated from
    AstroFeatureMetadata "1" *-- "1" TemperamentBalance : nested via temperament
    AstroFeatureMetadata "1" o-- "0..1" DetectedAstroAspect : top aspect
    AstroVectorResult "1" *-- "1" AstroFeatureMetadata : metadata
    AstroFortuneSlip "1" *-- "1" AnchorCaDao : anchors
    AstroFortuneSlip "1" o-- "0..1" AstroFeatureMetadata : context
```

Metadata giữ đủ temperament, top aspect, score và dominant signal theo `astroVectorEngine.ts:28-73`; bản cũ trong iOS đã bỏ các field này. `float32Array` là derived runtime representation nên Swift chỉ persist `[Double]` và cung cấp computed `[Float]`. Swift: `Astrology.swift`.

## 5. Wallpaper Studio

```mermaid
classDiagram
    direction LR
    class LuckyWallpaperRequest {
        +String fullName
        +String birthDate
        +Int lifePathNumber
        +Int destinyNumber
        +Int personalYearNumber
        +Int personalDayNumber
        +String intentionId
        +String styleId
        +String deviceType
        +String customWish
        +Int count
    }
    class LuckyWallpaperResponse {
        +Bool success
        +String[]? imageUrls
        +String? imageUrl
        +String? affirmationVi
        +String? explanationVi
        +String[]? luckyColorsVi
        +String? error
    }
    class WallpaperItem {
        +String id
        +String imageUrl
        +String title
        +String affirmationVi
        +String explanationVi
        +String[] luckyColorsVi
        +String styleName
        +String intentionName
    }
    class WallpaperStyleOption {
        +String id
        +String label
    }
    class WallpaperIntentionOption {
        +String id
        +String label
    }

    LuckyWallpaperRequest ..> LuckyWallpaperResponse : HTTP boundary
    LuckyWallpaperResponse "1" --> "0..4" WallpaperItem : maps successful URLs (inferred)
    WallpaperStyleOption ..> LuckyWallpaperRequest : supplies styleId
    WallpaperIntentionOption ..> LuckyWallpaperRequest : supplies intentionId
```

Quan hệ response-to-item là inferred từ mapper tại `WallpaperStudioScreen.tsx:466-486`; server có thể trả một URL hoặc mảng URL. Persistence của `WallpaperItem` vẫn là quyết định sản phẩm mở, không được thể hiện như hành vi parity đã tồn tại. Swift: `Wallpaper.swift`, `BoundaryModels.swift`.

## 6. Settings, notification và billing

```mermaid
classDiagram
    direction LR
    class BillingStatus {
        +Bool authenticated
        +BillingPlan plan
        +Bool? canManageBilling
        +Bool? checkoutPending
        +SubscriptionDetail? subscription
    }
    class SubscriptionDetail {
        +BillingProvider? provider
        +String? status
        +String? currentPeriodEnd
        +Bool? cancelAtPeriodEnd
    }
    class CheckoutRequest {
        +String locale
    }
    class CheckoutResponse {
        +String? checkoutUrl
        +String? approvalUrl
        +String? error
    }
    class DailyReminderSettings {
        +Bool enabled
        +Int hour
        +Int minute
        +Bool isValid
    }
    class NotificationPayload {
        +String title
        +String body
        +String url
    }

    BillingStatus "1" o-- "0..1" SubscriptionDetail : contains
    CheckoutRequest ..> CheckoutResponse : provider checkout
    DailyReminderSettings ..> NotificationPayload : schedules (inferred)
```

Quan hệ notification là inferred từ `dailyNotifications.ts:46-64`; payload mở deep link `numelyra://games/daily`. Coding keys snake_case của subscription được khai báo rõ trong Swift. Swift: `Billing.swift`, `BoundaryModels.swift`.

## 7. Game Hub và progress dùng chung

```mermaid
classDiagram
    direction LR
    class GameId {
        <<enumeration>>
        arrowEscape
        mindRules
        oAnQuan
        dotsBoxes
        sudoku
        game2048
        zip
    }
    class GameHubProgress {
        +Int version
        +Int streak
        +String? lastDailyDate
        +GameProgressSummary[String] games
    }
    class GameProgressSummary {
        +String? playedAt
        +Int completed
        +Int? total
        +Int? bestScore
    }
    class DailyChallenge {
        +String id
        +String dateKey
        +GameId gameId
        +String title
        +String subtitle
    }

    GameHubProgress "1" *-- "0..7" GameProgressSummary : keyed by GameId
    DailyChallenge --> GameId : selects one eligible game
    GameHubProgress ..> DailyChallenge : completion updates streak (inferred)
```

Quan hệ inferred được thực thi bởi `completeDailyChallenge` tại `gameHubStorage.ts:42-54`: cùng ngày không tăng lại, ngày kế tiếp tăng streak, ngày đứt quãng reset về 1. Swift: `GameHubModels.swift`.

## 8. Model riêng của các mini-game

```mermaid
classDiagram
    direction TB
    class ArrowEscape_Level {
        +Int id
        +ArrowEscape_Difficulty difficulty
        +ArrowEscape_GridSize gridSize
        +ArrowEscape_Arrow[] arrows
    }
    class ArrowEscape_Arrow {
        +String id
        +ArrowEscape_GridPosition[] path
        +ArrowEscape_GridPosition[] fullPath
    }
    class ArrowEscape_Board {
        +ArrowEscape_Level level
        +ArrowEscape_Arrow[] arrows
        +Int livesLeft
        +String[] removedIds
    }
    class ArrowEscape_Progress
    class SpaceGame_MiniBoard {
        +Int columns
        +Int rows
        +SpaceGame_MiniArrow[] arrows
    }
    class SpaceGame_MiniArrow {
        +String id
        +SpaceGame_AmmoType ammoType
    }
    class SpaceGame_State
    class MindRules_Puzzle {
        +Int id
        +MindRules_Equation[] equations
        +Int question
        +Int answer
    }
    class MindRules_Equation
    class OAnQuan_State {
        +OAnQuan_Cell[] cells
        +OAnQuan_Score[] scores
        +OAnQuan_Winner? winner
    }
    class OAnQuan_Cell
    class OAnQuan_Score
    class DotBox_State {
        +DotBox_Line[String] lines
        +DotBox_Box[] boxes
        +Int[] scores
    }
    class DotBox_Line
    class DotBox_Box
    class Sudoku_Board {
        +Sudoku_Cell[][] rows
    }
    class Sudoku_Cell
    class Game2048_Cell
    class Game2048_BestTileProgress
    class Zip_Puzzle {
        +Zip_Checkpoint[] checkpoints
        +Zip_Wall[]? walls
        +Zip_CellPosition[] solution
    }
    class Zip_Checkpoint
    class Zip_Wall
    class Zip_Progress
    class Zip_BestResult

    ArrowEscape_Level "1" *-- "1..*" ArrowEscape_Arrow : defines
    ArrowEscape_Board "1" --> "1" ArrowEscape_Level : current level
    ArrowEscape_Board "1" *-- "0..*" ArrowEscape_Arrow : remaining
    ArrowEscape_Progress ..> ArrowEscape_Level : restores level by id
    SpaceGame_MiniBoard "1" *-- "0..*" SpaceGame_MiniArrow : reload puzzle
    SpaceGame_State ..> SpaceGame_MiniBoard : consumes solved board
    MindRules_Puzzle "1" *-- "1..*" MindRules_Equation : examples
    OAnQuan_State "1" *-- "12" OAnQuan_Cell : board
    OAnQuan_State "1" *-- "2" OAnQuan_Score : players
    DotBox_State "1" *-- "0..*" DotBox_Line : edges
    DotBox_State "1" *-- "0..*" DotBox_Box : cells
    Sudoku_Board "1" *-- "81" Sudoku_Cell : 9 by 9
    Zip_Puzzle "1" *-- "1..*" Zip_Checkpoint : ordered checkpoints
    Zip_Puzzle "1" *-- "0..*" Zip_Wall : boundaries
    Zip_Progress "1" *-- "0..*" Zip_BestResult : keyed by puzzle id
```

Tên Mermaid được làm phẳng từ namespace Swift (`ArrowEscapeModels.Level`, `ZipModels.Puzzle`, v.v.) để tránh xung đột `Direction`, `Difficulty`, `Board` và `Puzzle`. Chỉ tree reachable được port: DotBox dưới `o-an-quan/src/dotbox`, không phải standalone duplicate `games/dots-boxes`. Swift: `MiniGameModels.swift`.

## 9. API và storage boundary

```mermaid
classDiagram
    direction LR
    class SupabaseBoundary {
        <<external>>
        profiles
        user_numerology_profiles
        numerology_knowledge
    }
    class RESTBoundary {
        <<external>>
        chatClassify
        chatAgent
        luckyWallpaper
        astroFortune
        billing
    }
    class KeychainBoundary {
        <<local secure>>
        authSession
    }
    class UserDefaultsBoundary {
        <<local key value>>
        profileList
        activeProfileId
        reminder
        gameProgress
    }
    class FileStoreBoundary {
        <<local file>>
        chatHistory
        astroCache
        wallpaperHistoryCandidate
    }
    class SQLiteBoundary {
        <<bundled database>>
        cadao
    }
    class BoundaryModels {
        +AccountProfileDTO
        +CloudNumerologyProfileDTO
        +ChatClassifyRequest
        +ChatAgentRequest
        +LuckyWallpaperRequest
        +AstroFortuneRequest
        +CheckoutRequest
    }
    class DomainModels {
        +UserProfile
        +ChatMessage
        +AstroFortuneSlip
        +WallpaperItem
        +GameHubProgress
        +CaDaoRecord
    }

    BoundaryModels --> SupabaseBoundary : Codable rows
    BoundaryModels --> RESTBoundary : Codable request response
    KeychainBoundary --> AuthSession : stores securely
    UserDefaultsBoundary --> DomainModels : small versioned payloads
    FileStoreBoundary --> DomainModels : larger histories and cache
    SQLiteBoundary --> CaDaoRecord : reads existing schema
    BoundaryModels ..> DomainModels : explicit mapper required
```

`SwiftData` không được coi là reader thay thế trực tiếp cho bundled `cadao.db`; boundary này phải dùng SQLite3 hoặc GRDB. Các key React Native cần được giữ trong migration adapter trước khi đổi tên. `ChatCardPayload.unsupported(JSONValue)` bảo toàn payload cũ không nhận diện được thay vì silently biến thành `{}`. Swift: `BoundaryModels.swift`, `ChatMessage.swift`.

## Kiểm chứng

- Số Mermaid block: 10.
- Mỗi inferred relationship đều có giải thích ngay sau diagram.
- Optionality quan trọng được biểu diễn bằng `?`.
- Tên trùng giữa các mini-game được namespace trong Swift và làm phẳng có tiền tố trong Mermaid.
- Mermaid CLI không có trong môi trường hiện tại; cú pháp được kiểm tra tĩnh theo `classDiagram` grammar.
