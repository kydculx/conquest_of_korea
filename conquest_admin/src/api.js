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
    .from('profiles')
    .update({ 
      gold: goldAmount, 
      last_gold_updated_at: new Date().toISOString() 
    })
    .eq('id', userId)
    .select();
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
export async function sendFcmNotification(title, body, targetTopic) {
  // 실제 Firebase Service Account 키를 프론트엔드 브라우저에 임베드하는 것은 보안 취약점이므로,
  // 관리자가 Supabase Edge Function을 호출하여 백그라운드 발송 처리를 대리 수행하거나,
  // 혹은 DB 내 공지사항 테이블(system_notices)에 레코드를 추가하여 백그라운드 DB Trigger/FCM 연동이 작동하도록 유도합니다.
  
  // 여기서는 로컬 대시보드 시뮬레이션 및 데이터 연동을 위해 임시 알림 이력 저장을 수행하도록 하겠습니다.
  // DB 스키마에 notices 등의 테이블이 있다면 저장이 가능하며, 없더라도 Edge function 목업 API를 연동합니다.
  console.log(`[FCM 발송 요청] 토픽: ${targetTopic}, 제목: ${title}, 본문: ${body}`);
  
  // 관리 운영 툴 기록용 (Supabase에 notices 테이블이 있다고 가정하고 insert 시도 후 실패 시 로그 대체)
  try {
    const { data, error } = await supabase
      .from('system_notices')
      .insert([
        {
          title,
          body,
          topic: targetTopic,
          created_at: new Date().toISOString()
        }
      ])
      .select();
    if (error) throw error;
    return data;
  } catch (e) {
    console.warn('⚠️ system_notices 테이블이 DB에 부재하거나 저장이 실패하여 로컬 로그로 대체합니다.', e);
    return { mockSuccess: true, title, body, topic: targetTopic };
  }
}
