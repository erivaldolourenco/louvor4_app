import 'package:flutter/material.dart';

class EventMusicCard extends StatelessWidget {

  final String title;
  final String artist;
  final String musicKey;
  const EventMusicCard({super.key, required this.title, required this.artist, required this.musicKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
              Positioned(
                top: -2, right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white, width: 2)),
                  child: Text(musicKey, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(artist, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.play_circle_fill, color: Colors.red, size: 30),
        ],
      ),
    );
  }
}