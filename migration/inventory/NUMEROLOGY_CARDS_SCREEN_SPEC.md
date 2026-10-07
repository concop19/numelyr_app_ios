# Numerology 24 Indicators screen — behavior and parity specification

## React Native source audited

- `src/components/NumerologyCardsModal.tsx`
- `src/components/IndicatorDetailModal.tsx`
- `src/components/MysticIndicatorDetailModal.tsx` (dormant in `ChatScreen.tsx`: `detailIndicator` is never set to a non-null value)
- `src/config/numerologyCards.ts`
- `src/services/numerologyEngine.ts`
- `src/services/numerologyKnowledge.ts`
- `src/store/userProfile.ts`
- Entry points in `src/screens/ChatScreen.tsx` and `src/screens/WallpaperStudioScreen.tsx`

## Reachable behavior

1. The 24 Indicators feature computes all 24 Pythagorean numerology indicators for the currently active profile (`activeProfile`) using `NumerologyRulesetVersion.reactNativeCardsV1`.
2. When an active profile is provided as input (`State(activeProfile:)`), the feature immediately derives the 24 cards for that profile; when omitted (`nil`), it loads the active profile via `UserProfileClient` (`@numelyra_profiles_list`, `@numelyra_active_profile_id`, fallback `@tieu_linh_mieu_profile`).
3. If the profile name or birth date is missing, the header subtitle falls back to `"Người Dùng"` and `"Chưa cập nhật"` while `NumerologyEngine` uses `"NGUOI DUNG"` and the current reference date.
4. Seven horizontal category filter pills filter the 24 cards:
   - `Tất Cả` (24 cards)
   - `Cốt Lõi` (5 cards: `01`–`05`)
   - `Tiềm Năng` (6 cards: `06`–`11`)
   - `Nợ Nghiệp` (2 cards: `12`–`13`)
   - `Cầu Nối` (3 cards: `14`–`16`)
   - `Vận Hạn` (5 cards: `17`–`21`)
   - `Biểu Đồ` (3 cards: `22`–`24`)
5. Switching to a different category tab triggers selection haptics (`HapticClient.selection`).
6. Each card in the 2-column grid displays:
   - Artwork from `Assets.xcassets/NumerologyCards/` (`1 : 1.38` aspect ratio)
   - Top-left number badge (`#01`..`#24`)
   - Top-right category tag (`Cốt Lõi`, `Tiềm Năng`, `Nghiệp & Cầu Nối`, `Vận Hạn Chu Kỳ`, `Biểu Đồ Ma Trận`)
   - Bottom value overlay (`Chỉ số: <displayValue>`), styled with purple/gold Master accents when `isMaster == true` (`11`, `22`, `33`)
   - Vietnamese title (`nameVi`) and English subtitle (`nameEn`)
7. Tapping any card triggers light impact haptics (`HapticClient.lightImpact`) and opens the detail sheet (`IndicatorDetailView`).
8. The detail sheet queries `NumerologyClient.indicatorReading` (backed by the 212 articles in `cadao.db` `numerology_knowledge` with offline Archetype and Personal Year fallbacks) and renders:
   - Hero card artwork (`105×155`), Vietnamese/English titles, result value pill, optional `Master` badge, and card description
   - Knowledge banner (`Luận giải tri thức chuẩn Pythagoras • Tức thì & Không qua AI`)
   - Four structured sections: `Bản Chất Cốt Lõi & Năng Lượng`, `Điểm Mạnh Tự Nhiên`, `Vùng Bóng Tối Cần Lưu Ý`, `Lời Khuyên & Bước Chuyển Hóa`
   - Expandable full-article toggle (`Đọc toàn văn tư liệu gốc` / `Thu gọn bài luận giải`) when `fullContent.count > 300`, with selection haptics
   - Footer confirmation button (`Đã Hiểu • Quay Lại 24 Lá Bài`) that triggers success notification haptics (`HapticClient.success`) and dismisses the sheet.

## Native iOS mapping

- `NumerologyCardsFeature` (`Features/NumerologyCards/NumerologyCardsFeature.swift`) is a standalone TCA `@Reducer` owning `activeProfile`, `selectedCategory`, `indicators` and `@Presents var detail: IndicatorDetailFeature.State?`.
- `NumerologyCardsView` (`Features/NumerologyCards/NumerologyCardsView.swift`) renders the exact dark-mode UI (`#070913` background, `#0F1528` card containers, `#E5A93C` / `#FCD34D` gold accents, purple Master badge overlays).
- `IndicatorDetailFeature` and `IndicatorDetailView` own the detail sheet state, reading lookup, full-article expansion and confirmation dismissal.
- `NumerologyCardCatalog` (`Shared/Models/NumerologyCardCatalog.swift`) defines all 24 `NumerologyCardDefinition` records matching `src/config/numerologyCards.ts`.
- `NumerologyClient`, `UserProfileClient` and `HapticClient` isolate all calculation, persistence, SQLite and haptic side effects from SwiftUI views.

## Acceptance criteria

- All 24 cards render in stable `01`..`24` order with matching Vietnamese/English titles, category tags, bundled card images and computed values.
- Category tabs filter the exact card counts (`24`, `5`, `6`, `2`, `3`, `5`, `3`) and fire selection haptics only when changing to a different tab.
- Master numbers (`11`, `22`, `33`) display the purple/gold Master styling both on the grid card and in the detail sheet hero pill.
- Opening any card loads its corresponding `KnowledgeReading` from `NumerologyClient` and supports toggling the full source article when `fullContent.count > 300`.
