import { supabase } from './supabase';

/**
 * 1. 대시보드 통계 및 랭킹 수집
 */
export async function fetchDashboardStats() {
  try {
    // 총 사용자 수
    const { count: usersCount, error: err1 } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true });
    
    if (err1) throw err1;

    // 총 점령지 수
    const { count: tilesCount, error: err2 } = await supabase
      .from('captured_tiles')
      .select('*', { count: 'exact', head: true });
      
    if (err2) throw err2;

    // 총 유통 골드량
    const { data: goldData, error: err3 } = await supabase
      .from('profiles')
      .select('gold');
      
    if (err3) throw err3;
    const totalGold = goldData.reduce((sum, item) => sum + (Number(item.gold) || 0), 0);

    // 상위 5명 사용자 랭킹 (점령 구역 순)
    const { data: topAgents, error: err4 } = await supabase
      .from('profiles')
      .select('id, nickname, color_hex, captured_tiles_count, gold')
      .neq('role', 'admin')
      .order('captured_tiles_count', { ascending: false })
      .limit(5);

    if (err4) throw err4;

    return {
      usersCount: usersCount || 0,
      tilesCount: tilesCount || 0,
      totalGold: Math.round(totalGold * 10) / 10,
      topAgents: topAgents || [],
    };
  } catch (error) {
    console.error('fetchDashboardStats error:', error);
    throw error;
  }
}

/**
 * 2. 사용자(User) 관리 API
 */
export async function fetchUsers() {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

export async function updateUserGold(userId, goldAmount) {
  const { data, error } = await supabase
    .rpc('update_user_gold_admin', {
      p_user_id: userId,
      p_gold_amount: goldAmount
    });
  if (error) throw error;
  return data;
}

export async function updateUserMainBase(userId, mainBaseTileId) {
  const { data, error } = await supabase
    .rpc('update_user_main_base_admin', {
      p_user_id: userId,
      p_main_base_tile_id: mainBaseTileId
    });
  if (error) throw error;
  return data;
}

export async function deleteUser(userId) {
  const { data, error } = await supabase
    .rpc('delete_user_by_admin', {
      p_user_id: userId
    });
  if (error) throw error;
  return data;
}

/**
 * 3. 영토(Tile) 및 점령 현황 제어 API
 */
export async function fetchTiles() {
  const { data, error } = await supabase
    .from('captured_tiles')
    .select('*')
    .order('captured_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

export async function fetchUserCapturedTiles(userId) {
  const { data, error } = await supabase
    .from('captured_tiles')
    .select('*')
    .eq('user_id', userId)
    .order('captured_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

export async function neutralizeTile(tileId) {
  const { error } = await supabase
    .from('captured_tiles')
    .delete()
    .eq('id', tileId);
  if (error) throw error;
}

export async function transferTileOwnership(tileId, userId, userColor) {
  const { data, error } = await supabase
    .from('captured_tiles')
    .update({
      user_id: userId,
      color_hex: userColor,
      captured_at: new Date().toISOString(),
      // 소유주 변경 시 쉴드는 즉시 만료(0초) 또는 리셋 처리
      shield_expiration: new Date(0).toISOString(), 
    })
    .eq('id', tileId)
    .select();
  if (error) throw error;
  return data;
}

export async function updateTileShield(tileId, extraHours) {
  const expiration = new Date();
  expiration.setHours(expiration.getHours() + Number(extraHours));

  const { data, error } = await supabase
    .from('captured_tiles')
    .update({
      shield_expiration: expiration.toISOString()
    })
    .eq('id', tileId)
    .select();
  if (error) throw error;
  return data;
}

/**
 * 4. 글로벌 시스템 설정 API (system_settings)
 */
export async function fetchSystemSettings() {
  const { data, error } = await supabase
    .from('system_settings')
    .select('*');
  if (error) throw error;
  return data || [];
}

export async function updateGoldRate(newValue) {
  const { data, error } = await supabase
    .from('system_settings')
    .update({ value: Number(newValue) })
    .eq('key', 'gold_rate')
    .select();
  if (error) throw error;
  return data;
}

/**
 * 5. FCM 알림 전송 (시뮬레이션 혹은 Edge Function 트리거용)
 */
export async function sendFcmNotification(title, body, targetTopic, notifType = 'system_notice', tileId = '') {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseKey) {
    throw new Error('Supabase URL or Anon Key is missing.');
  }

  console.log(`[FCM 발송 요청] 토픽: ${targetTopic}, 제목: ${title}, 본문: ${body} | 타입: ${notifType} | 타일ID: ${tileId}`);
  
  const response = await fetch(`${supabaseUrl}/functions/v1/send-push`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${supabaseKey}`,
      'apikey': supabaseKey,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      topic: targetTopic,
      title: title,
      body: body,
      data_payload: {
        type: notifType,
        tile_id: tileId
      }
    })
  });

  const resData = await response.json();
  
  if (!response.ok) {
    throw new Error(resData.error || `HTTP 에러 status: ${response.status}`);
  }

  return resData;
}

/**
 * 6. 사용자 업적(Achievement) 모니터링 API
 */
export async function fetchUserAchievements(userId) {
  const { data, error } = await supabase
    .from('user_achievements')
    .select('achievement_id, unlocked_at')
    .eq('user_id', userId)
    .order('unlocked_at', { ascending: true });
  if (error) throw error;
  return data || [];
}

/**
 * 7. 타일 속성 맵 에디터 API (타입 및 속성 관리)
 */

// 기본 프리셋 타입 세트
export const DEFAULT_TILE_TYPES = [
  { id: 0, name: '기본 타일 (Default)', color_hex: '#334155', description: '일반 평지 및 기본 타일 구역', is_blocked: false },
  { id: 1, name: '보너스 거점 (Bonus)', color_hex: '#fbbf24', description: '추가 보상 및 점령 포인트 획득 구역', is_blocked: false },
  { id: 2, name: '진입 불가 (Restricted)', color_hex: '#ef4444', description: '플레이어 진입이 차단된 위험 구역', is_blocked: true },
  { id: 3, name: '트래킹 코스 (Trail)', color_hex: '#10b981', description: '걷기/런닝 추천 및 가중치 경로', is_blocked: false },
  { id: 4, name: '랜드마크 (Landmark)', color_hex: '#a855f7', description: '특수 이벤트 및 미션 목적지', is_blocked: false },
];

const LOCAL_STORAGE_TYPES_KEY = 'conquest_map_tile_types';
const LOCAL_STORAGE_ATTRIBUTES_KEY = 'conquest_map_tile_attributes';

/**
 * 타일 타입 목록 조회 (Supabase 우선, Fallback으로 로컬스토리지/기본 프리셋)
 */
export async function fetchTileTypes() {
  try {
    const { data, error } = await supabase
      .from('map_tile_types')
      .select('*')
      .order('id', { ascending: true });

    if (error || !data || data.length === 0) {
      const local = localStorage.getItem(LOCAL_STORAGE_TYPES_KEY);
      if (local) return JSON.parse(local);
      return DEFAULT_TILE_TYPES;
    }
    localStorage.setItem(LOCAL_STORAGE_TYPES_KEY, JSON.stringify(data));
    return data;
  } catch (err) {
    console.warn('⚠️ Supabase map_tile_types 조회 실패, 로컬 스토리지 데이터 사용:', err);
    const local = localStorage.getItem(LOCAL_STORAGE_TYPES_KEY);
    return local ? JSON.parse(local) : DEFAULT_TILE_TYPES;
  }
}

/**
 * 타일 타입 추가 또는 수정
 */
export async function saveTileType(typeData) {
  try {
    await supabase.from('map_tile_types').upsert({
      id: Number(typeData.id),
      name: typeData.name,
      color_hex: typeData.color_hex,
      description: typeData.description || '',
      is_blocked: Boolean(typeData.is_blocked),
    });
  } catch (err) {
    console.warn('⚠️ Supabase map_tile_types upsert 실패 (로컬 저장 유지):', err);
  }

  // 로컬 스토리지 동기화
  const currentTypes = await fetchTileTypes();
  const existingIdx = currentTypes.findIndex(t => Number(t.id) === Number(typeData.id));
  if (existingIdx >= 0) {
    currentTypes[existingIdx] = { ...currentTypes[existingIdx], ...typeData };
  } else {
    currentTypes.push(typeData);
  }
  localStorage.setItem(LOCAL_STORAGE_TYPES_KEY, JSON.stringify(currentTypes));
  return currentTypes;
}

/**
 * 타일 타입 삭제
 */
export async function deleteTileType(typeId) {
  if (Number(typeId) === 0) {
    throw new Error('기본 타일(0번) 타입은 삭제할 수 없습니다.');
  }
  try {
    await supabase.from('map_tile_types').delete().eq('id', typeId);
  } catch (err) {
    console.warn('⚠️ Supabase map_tile_types delete 실패:', err);
  }

  const currentTypes = (await fetchTileTypes()).filter(t => Number(t.id) !== Number(typeId));
  localStorage.setItem(LOCAL_STORAGE_TYPES_KEY, JSON.stringify(currentTypes));
  return currentTypes;
}

/**
 * 속성이 부여된 타일 전체 목록 조회 (Map 형태 반환: { "q_r": { type_id, memo, ... } })
 */
export async function fetchTileAttributes() {
  try {
    const { data, error } = await supabase
      .from('map_tile_attributes')
      .select('*');

    if (error || !data) {
      const local = localStorage.getItem(LOCAL_STORAGE_ATTRIBUTES_KEY);
      return local ? JSON.parse(local) : {};
    }

    const resultMap = {};
    data.forEach(item => {
      resultMap[item.id] = item;
    });
    localStorage.setItem(LOCAL_STORAGE_ATTRIBUTES_KEY, JSON.stringify(resultMap));
    return resultMap;
  } catch (err) {
    console.warn('⚠️ Supabase map_tile_attributes 조회 실패, 로컬 캐시 사용:', err);
    const local = localStorage.getItem(LOCAL_STORAGE_ATTRIBUTES_KEY);
    return local ? JSON.parse(local) : {};
  }
}

/**
 * 변경된 타일 속성 일괄 저장
 */
export async function saveTileAttributes(attributesMap) {
  const records = Object.values(attributesMap).map(item => ({
    id: item.id,
    q: item.q,
    r: item.r,
    type_id: Number(item.type_id || 0),
    memo: item.memo || '',
    updated_at: new Date().toISOString(),
  }));

  // 로컬 스토리지 즉시 캐시
  localStorage.setItem(LOCAL_STORAGE_ATTRIBUTES_KEY, JSON.stringify(attributesMap));

  if (records.length > 0) {
    try {
      const { error } = await supabase.from('map_tile_attributes').upsert(records);
      if (error) throw error;
    } catch (err) {
      console.warn('⚠️ Supabase map_tile_attributes 일괄 저장 실패 (로컬 스토리지 유지):', err);
    }
  }

  return attributesMap;
}

