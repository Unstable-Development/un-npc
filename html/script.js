// Configuration data (populated from Lua)
let guardZonesData = [];
let patrolRoutesData = [];
let bodyguardTiersData = [];
let scenariosData = [];
let aggressiveZonesData = [];

// Initialize UI
$(document).ready(function() {
    // Tab navigation
    $('.nav-btn').click(function() {
        const tab = $(this).data('tab');
        
        $('.nav-btn').removeClass('active');
        $(this).addClass('active');
        
        $('.tab-panel').removeClass('active');
        $(`#${tab}-tab`).addClass('active');
    });

    // Close button
    $('#closeBtn').click(function() {
        closeTablet();
    });

    // ESC key to close
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            closeTablet();
        }
    });

    // Range sliders
    $('#hunterLevel').on('input', function() {
        $('#hunterLevelValue').text($(this).val());
    });

    $('#hunterCount').on('input', function() {
        $('#hunterCountValue').text($(this).val());
    });

    // Toggle guard zones
    $('#toggleGuardZones').change(function() {
        const enabled = $(this).is(':checked');
        sendNUIMessage('toggleGuardZones', { enabled: enabled });
    });

    // Clear all patrols
    $('#clearAllPatrols').click(function() {
        sendNUIMessage('clearAllPatrols');
    });

    // Spawn hunters
    $('#spawnHunters').click(function() {
        const level = parseInt($('#hunterLevel').val());
        const count = parseInt($('#hunterCount').val());
        const targetId = parseInt($('#hunterTargetId').val()) || 0;
        const hunterType = $('#hunterType').val();
        
        sendNUIMessage('spawnHunters', { 
            level: level, 
            count: count,
            targetId: targetId,
            hunterType: hunterType
        });
    });

    // Clear hunters
    $('#clearHunters').click(function() {
        sendNUIMessage('clearHunters');
    });

    // Give bodyguard to player
    $('#giveBodyguard').click(function() {
        const playerId = parseInt($('#targetPlayerId').val());
        const tier = parseInt($('#bodyguardTier').val());
        
        if (!playerId || isNaN(playerId)) {
            showNotification('Please enter a valid player ID', 'error');
            return;
        }
        
        sendNUIMessage('giveBodyguard', { playerId: playerId, tier: tier });
    });

    // Clear bodyguards from player
    $('#clearBodyguards').click(function() {
        const playerId = parseInt($('#targetPlayerId').val());
        
        if (!playerId || isNaN(playerId)) {
            showNotification('Please enter a valid player ID', 'error');
            return;
        }
        
        sendNUIMessage('clearBodyguards', { playerId: playerId });
    });

    // Create zone button
    $('#createZoneBtn').click(function() {
        sendNUIMessage('createZone');
        closeTablet();
    });

    // Create route button
    $('#createRouteBtn').click(function() {
        sendNUIMessage('createRoute');
        closeTablet();
    });

    // Spawn all aggressive zones
    $('#spawnAllAggressiveZones').click(function() {
        sendNUIMessage('spawnAllAggressiveZones');
    });

    // Clear all aggressive zones
    $('#clearAllAggressiveZones').click(function() {
        if (confirm('Clear all street NPC zones?')) {
            sendNUIMessage('clearAllAggressiveZones');
        }
    });

    // Quick Actions
    $('#spawnAllGuards').click(function() {
       sendNUIMessage('spawnAllGuards');
    });

    $('#clearEverything').click(function() {
        if (confirm('Are you sure you want to clear ALL NPCs? This cannot be undone.')) {
            sendNUIMessage('clearEverything');
        }
    });

    $('#emergencyLockdown').click(function() {
        sendNUIMessage('emergencyLockdown');
    });

    $('#performanceCheck').click(function() {
        sendNUIMessage('performanceCheck');
    });

    // Warning system toggle
    $('#toggleWarnings').change(function() {
        const enabled = $(this).is(':checked');
        sendNUIMessage('toggleWarnings', { enabled: enabled });
    });

    // AI behaviors toggle
    $('#toggleAI').change(function() {
        const enabled = $(this).is(':checked');
        sendNUIMessage('toggleAI', { enabled: enabled });
    });
});

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openTablet':
            openTablet(data.data);
            break;
        case 'closeTablet':
            closeTablet();
            break;
        case 'updateData':
            updateData(data.data);
            break;
        case 'notification':
            showNotification(data.message, data.type);
            break;
    }
});

function openTablet(data) {
    if (data) {
        updateData(data);
    }
    $('#tablet').addClass('show');
    $('body').css('display', 'flex');
}

function closeTablet() {
    $('#tablet').removeClass('show');
    setTimeout(() => {
        $('body').css('display', 'none');
    }, 300);
    
    $.post('https://prelude-npc/closeUI');
}

function updateData(data) {
    if (data.aggressiveZones) {
        aggressiveZonesData = data.aggressiveZones;
        populateAggressiveZones();
    }

    if (data.guardZones) {
        guardZonesData = data.guardZones;
        populateGuardZones();
    }
    
    if (data.patrolRoutes) {
        patrolRoutesData = data.patrolRoutes;
        populatePatrolRoutes();
    }
    
    if (data.bodyguardTiers) {
        bodyguardTiersData = data.bodyguardTiers;
        populateBodyguardTiers();
    }

    if (data.scenarios) {
        scenariosData = data.scenarios;
        populateScenarios();
    }
}

function populateAggressiveZones() {
    const container = $('#aggressiveZonesList');
    container.empty();

    if (aggressiveZonesData.length === 0) {
        container.html(`
            <div class="empty-state">
                <i class="fas fa-fist-raised"></i>
                <p>No street NPC zones configured</p>
            </div>
        `);
        return;
    }

    aggressiveZonesData.forEach((zone, index) => {
        const statusBadge = zone.active
            ? '<span class="active-badge">Active</span>'
            : '<span class="inactive-badge">Inactive</span>';

        const card = $(`
            <div class="zone-card aggressive-zone-card">
                <div class="card-header">
                    <div class="card-title">
                        <i class="fas fa-fist-raised"></i> ${zone.name}
                        ${statusBadge}
                    </div>
                </div>
                <div class="card-info">
                    <div class="info-item"><span class="info-label">NPCs:</span> ${zone.npcCount}</div>
                    <div class="info-item"><span class="info-label">Radius:</span> ${zone.radius}m</div>
                    <div class="info-item"><span class="info-label">Attack Range:</span> ${zone.attackRange}m</div>
                    <div class="info-item"><span class="info-label">Health:</span> ${zone.health} | <span class="info-label">Armor:</span> ${zone.armor}</div>
                    <div class="info-item"><span class="info-label">Accuracy:</span> ${zone.accuracy}%</div>
                    <div class="info-item"><span class="info-label">Weapons:</span> Melee Only</div>
                </div>
                <div class="card-actions">
                    <button class="card-btn spawn" data-zone="${index + 1}">
                        <i class="fas fa-plus"></i> Spawn
                    </button>
                    <button class="card-btn clear" data-zone="${index + 1}">
                        <i class="fas fa-trash"></i> Clear
                    </button>
                </div>
            </div>
        `);

        card.find('.spawn').click(function() {
            sendNUIMessage('spawnAggressiveZone', { zoneId: $(this).data('zone') });
        });

        card.find('.clear').click(function() {
            sendNUIMessage('clearAggressiveZone', { zoneId: $(this).data('zone') });
        });

        container.append(card);
    });
}

function populateGuardZones() {
    const container = $('#zonesList');
    container.empty();
    
    if (guardZonesData.length === 0) {
        container.html(`
            <div class="empty-state">
                <i class="fas fa-shield-alt"></i>
                <p>No guard zones configured</p>
                <button class="action-btn primary" id="createFirstZone">
                    <i class="fas fa-plus-circle"></i> Create Your First Zone
                </button>
            </div>
        `);
        
        $('#createFirstZone').click(function() {
            sendNUIMessage('createZone');
            closeTablet();
        });
        return;
    }
    
    guardZonesData.forEach((zone, index) => {
        const isCustom = zone.isCustom === true || zone.isCustom === 1;
        const deleteBtn = isCustom ? `
            <button class="card-btn delete" data-zone-name="${zone.name}" title="Delete Zone">
                <i class="fas fa-times"></i>
            </button>
        ` : '';
        
        const customBadge = isCustom ? '<span class="custom-badge">Custom</span>' : '<span class="preset-badge">Preset</span>';
        
        const card = $(`
            <div class="zone-card">
                <div class="card-header">
                    <div class="card-title">
                        <i class="fas fa-map-marker-alt"></i> ${zone.name}
                        ${customBadge}
                    </div>
                </div>
                <div class="card-info">
                    <div class="info-item">
                        <span class="info-label">Guards:</span> ${zone.guardCount}
                    </div>
                    <div class="info-item">
                        <span class="info-label">Radius:</span> ${zone.radius}m
                    </div>
                    <div class="info-item">
                        <span class="info-label">Required Item:</span> ${zone.requiredItem || 'None'}
                    </div>
                    <div class="info-item">
                        <span class="info-label">Health:</span> ${zone.health} | <span class="info-label">Armor:</span> ${zone.armor}
                    </div>
                    <div class="info-item">
                        <span class="info-label">Accuracy:</span> ${zone.accuracy}%
                    </div>
                </div>
                <div class="card-actions">
                    <button class="card-btn spawn" data-zone="${index + 1}">
                        <i class="fas fa-plus"></i> Spawn
                    </button>
                    <button class="card-btn clear" data-zone="${index + 1}">
                        <i class="fas fa-trash"></i> Clear
                    </button>
                    ${deleteBtn}
                </div>
            </div>
        `);
        
        card.find('.spawn').click(function() {
            const zoneId = $(this).data('zone');
            sendNUIMessage('spawnGuards', { zoneId: zoneId });
        });
        
        card.find('.clear').click(function() {
            const zoneId = $(this).data('zone');
            sendNUIMessage('clearGuards', { zoneId: zoneId });
        });
        
        if (isCustom) {
            card.find('.delete').click(function() {
                const zoneName = $(this).data('zone-name');
                if (confirm(`Are you sure you want to delete zone "${zoneName}"? This cannot be undone.`)) {
                    sendNUIMessage('deleteZone', { zoneName: zoneName });
                }
            });
        }
        
        container.append(card);
    });
}

function populatePatrolRoutes() {
    const container = $('#patrolsList');
    container.empty();
    
    if (patrolRoutesData.length === 0) {
        container.html(`
            <div class="empty-state">
                <i class="fas fa-car"></i>
                <p>No patrol routes configured</p>
                <button class="action-btn primary" id="createFirstRoute">
                    <i class="fas fa-plus-circle"></i> Create Your First Route
                </button>
            </div>
        `);
        
        $('#createFirstRoute').click(function() {
            sendNUIMessage('createRoute');
            closeTablet();
        });
        return;
    }
    
    patrolRoutesData.forEach((route, index) => {
        const isCustom = route.isCustom === true || route.isCustom === 1;
        const deleteBtn = isCustom ? `
            <button class="card-btn delete" data-route-name="${route.name}" title="Delete Route">
                <i class="fas fa-times"></i>
            </button>
        ` : '';
        
        const customBadge = isCustom ? '<span class="custom-badge">Custom</span>' : '<span class="preset-badge">Preset</span>';
        
        const card = $(`
            <div class="patrol-card">
                <div class="card-header">
                    <div class="card-title">
                        <i class="fas fa-route"></i> ${route.name}
                        ${customBadge}
                    </div>
                </div>
                <div class="card-info">
                    <div class="info-item">
                        <span class="info-label">Vehicle:</span> ${route.vehicleModel}
                    </div>
                    <div class="info-item">
                        <span class="info-label">Speed:</span> ${route.speed} km/h
                    </div>
                    <div class="info-item">
                        <span class="info-label">Waypoints:</span> ${route.waypointCount || (route.waypoints ? route.waypoints.length : 0)}
                    </div>
                    <div class="info-item">
                        <span class="info-label">Weapon:</span> ${route.weapon}
                    </div>
                </div>
                <div class="card-actions">
                    <button class="card-btn spawn" data-route="${index + 1}">
                        <i class="fas fa-play"></i> Start Patrol
                    </button>
                    ${deleteBtn}
                </div>
            </div>
        `);
        
        card.find('.spawn').click(function() {
            const routeId = $(this).data('route');
            sendNUIMessage('spawnPatrol', { routeId: routeId });
        });
        
        if (isCustom) {
            card.find('.delete').click(function() {
                const routeName = $(this).data('route-name');
                if (confirm(`Are you sure you want to delete route "${routeName}"? This cannot be undone.`)) {
                    sendNUIMessage('deleteRoute', { routeName: routeName });
                }
            });
        }
        
        container.append(card);
    });
}

function populateBodyguardTiers() {
    const container = $('#bodyguardTiers');
    container.empty();
    
    const tierIcons = ['fa-user', 'fa-user-shield', 'fa-user-secret'];
    
    bodyguardTiersData.forEach((tier, index) => {
        const card = $(`
            <div class="tier-card">
                <div class="tier-icon">
                    <i class="fas ${tierIcons[index]}"></i>
                </div>
                <div class="tier-name">${tier.name}</div>
                <div class="tier-price">$${tier.price.toLocaleString()}</div>
                <div class="tier-stats">
                    <p><strong>Duration:</strong> ${tier.duration} min</p>
                    <p><strong>Health:</strong> ${tier.health}</p>
                    <p><strong>Armor:</strong> ${tier.armor}</p>
                    <p><strong>Accuracy:</strong> ${tier.accuracy}%</p>
                </div>
            </div>
        `);
        
        container.append(card);
    });
}

function sendNUIMessage(action, data = {}) {
    $.post(`https://prelude-npc/${action}`, JSON.stringify(data));
}

function showNotification(message, type) {
    // This will be handled by the game's notification system
    console.log(`[${type}] ${message}`);
}

function populateScenarios() {
    const container = $('#scenariosList');
    container.empty();
    
    if (scenariosData.length === 0) {
        container.html(`
            <div class="empty-state">
                <i class="fas fa-theater-masks"></i>
                <p>No scenarios configured</p>
            </div>
        `);
        return;
    }
    
    scenariosData.forEach((scenario, index) => {
        const card = $(`
            <div class="scenario-card">
                <div class="scenario-icon">
                    <i class="fas ${scenario.icon || 'fa-star'}"></i>
                </div>
                <div class="scenario-content">
                    <div class="scenario-title">${scenario.name}</div>
                    <div class="scenario-description">${scenario.description}</div>
                    <div class="scenario-details">
                        <span><i class="fas fa-shield-alt"></i> ${scenario.zones.length} zones</span>
                        <span><i class="fas fa-route"></i> ${scenario.patrols.length} patrols</span>
                    </div>
                </div>
                <div class="scenario-actions">
                    <button class="card-btn spawn" data-scenario="${scenario.name}">
                        <i class="fas fa-play"></i> Activate
                    </button>
                    <button class="card-btn clear" data-scenario="${scenario.name}">
                        <i class="fas fa-stop"></i> Deactivate
                    </button>
                </div>
            </div>
        `);
        
        card.find('.spawn').click(function() {
            const scenarioName = $(this).data('scenario');
            sendNUIMessage('activateScenario', { scenarioName: scenarioName });
        });
        
        card.find('.clear').click(function() {
            const scenarioName = $(this).data('scenario');
            sendNUIMessage('deactivateScenario', { scenarioName: scenarioName });
        });
        
        container.append(card);
    });
}
