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

export async function deleteUser(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .delete()
    .eq('id', userId);
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
